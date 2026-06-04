---
id: PF-STA-103
type: Document
category: General
version: 1.0
created: 2026-05-05
updated: 2026-05-05
task_name: framework-blueprint-sync-task-creation
---

# Temporary Task Creation State: framework-blueprint-sync-task-creation

> **⚠️ TEMPORARY FILE**: This file tracks multi-session implementation of task creation infrastructure. Move to `process-framework-local/state-tracking/temporary/old` after all components are implemented.

## Task Overview

- **Task Name**: framework-blueprint-sync-task-creation
- **Task ID**: [To be assigned by ../New-Task.ps1]
- **Purpose**: Create a new support task that propagates framework improvements made inside a real project (e.g., LinkWatcher) back to the corresponding FrameworkBuilder blueprint (e.g., `FrameworkBuilder/appdev/`).
- **Initial Validation Case**: Sync 5 structural drift items between `LinkWatcher/test/` and `FrameworkBuilder/appdev/test/`, found during a 2026-05-05 comparison session. The new task should be exercised against this case as its first real run.

## Context

- **FrameworkBuilder layout**: `FrameworkBuilder/` contains multiple framework variants. `FrameworkBuilder/appdev/` is the project blueprint used by LinkWatcher (process-framework + doc + test + src + CLAUDE.md). Other variants live under `FrameworkBuilder/AIAgentDocumentationFramework/AADF/` and are tracked in `FrameworkBuilder/Framework_Registry.json`.
- **Working assumption**: improvements are made at the project level (in real working projects, where they get tested in real use), not directly in the blueprint. The new sync task is the formal mechanism to propagate them back.
- **Scope of new task**: not limited to `test/` — covers all top-level directories of a chosen framework variant (process-framework, doc, test, src, CLAUDE.md, etc.). User specifies which framework variant to target.

## Infrastructure Analysis

### Required Artifacts

List all artifacts needed for this task:

| Artifact Type | Name                 | Status                      | Priority          | Notes   |
| ------------- | -------------------- | --------------------------- | ----------------- | ------- |
| Directory     | [directory-name]     | [NEEDED/EXISTS]             | [HIGH/MEDIUM/LOW] | [Notes] |
| Template      | [template-name.md]   | [NEEDED/EXISTS/PLACEHOLDER] | [HIGH/MEDIUM/LOW] | [Notes] |
| Guide         | [guide-name.md]      | [NEEDED/EXISTS/PLACEHOLDER] | [HIGH/MEDIUM/LOW] | [Notes] |
| Script        | [script-name.ps1]    | [NEEDED/EXISTS/PLACEHOLDER] | [HIGH/MEDIUM/LOW] | [Notes] |
| State File    | [state-file-name.md] | [NEEDED/EXISTS/PLACEHOLDER] | [HIGH/MEDIUM/LOW] | [Notes] |

### Available for Reuse

List existing artifacts that can be reused:

| Artifact        | Location | Reuse Notes            |
| --------------- | -------- | ---------------------- |
| [artifact-name] | [path]   | [How it can be reused] |

## Implementation Roadmap

### Phase 1: Core Task Infrastructure (Session 1)

**Priority**: HIGH - Must complete before task can be used

- [x] **Task Definition File**: Created — **PF-TSK-087** at `process-framework/tasks/support/framework-blueprint-sync-task.md`
  - **Status**: COMPLETED (2026-05-05)
  - **Command run**: `New-Task.ps1 -TaskName "framework-blueprint-sync" -WorkflowPhase "support" -Description "..."`
  - **Notes**: v1 task definition populated with full process steps, role, checklist, and outputs. Will be exercised against the 5-item validation case (LinkWatcher test/ → FrameworkBuilder/appdev/test/) as its first real run. Refinement expected via Framework Evaluation (PF-TSK-079) after first execution.

- [ ] **Evaluate Task File Creation Requirements**: Determine if task creates new files as outputs
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Decision**: [CREATES_FILES/NO_FILES_CREATED]
  - **File Types**: [List types of files the task will create, if any]
  - **Notes**: This decision determines if document creation infrastructure is needed

### Phase 2: Document Creation Infrastructure (Session 2)

**Priority**: HIGH - Only execute if Phase 1 determined CREATES_FILES

> **⚠️ CONDITIONAL PHASE**: Only execute if task creates new files as outputs

- [ ] **Task Output Directory**: Create directory structure for task outputs

  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED/SKIPPED]
  - **Dependencies**: Task definition completed, file types identified
  - **Directories**: [List specific directories needed - include full paths with subdirectories, e.g., doc/technical/api/specifications/specifications/]
  - **Command**: `mkdir -p [directory-path]` or manual creation
  - **Notes**: Create the directory where task outputs will be stored. Consider using subdirectories for better organization of different file types.

- [ ] **Document Creation Script**: Create script for generating new files using [document-creation-script-development-guide.md](../../guides/support/document-creation-script-development-guide.md)

  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED/SKIPPED]
  - **Dependencies**: Task definition completed, directory structure created
  - **Guide**: [Document Creation Script Development Guide](../../guides/support/document-creation-script-development-guide.md)
  - **Template**: [Document Creation Script Template](document-creation-script-template.ps1)
  - **Location**: [Where the script will be placed - e.g., process-framework/scripts/file-creation/[category]/New-[ScriptName].ps1]
  - **Notes**: Script that generates files created by the task

- [ ] **ID Registry Update**: Update the appropriate ID registry (PF/PD/TE-id-registry.json) with new ID prefix for file types
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED/SKIPPED]
  - **Dependencies**: Understanding of what file types the task will create
  - **File**: `process-framework/PF-id-registry.json` (or PD/TE registry as appropriate)
  - **New Prefix**: [e.g., PF-XXX or PD-XXX]
  - **Directory Mapping**: [Directory where files will be stored - include subdirectories if needed, e.g., doc/technical/api/specifications/specifications]
  - **Notes**: Add new prefix entry with appropriate directory mapping. Use subdirectories for better organization when task creates multiple file types.

### Phase 3: Templates and Guides (Session 3)

**Priority**: MEDIUM - Needed for full functionality

- [ ] **Task-Specific Template**: Create template using [template-development-guide.md](../../guides/support/template-development-guide.md) and [New-Template.ps1](../../scripts/file-creation/support/New-Template.ps1)

  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED/SKIPPED]
  - **Dependencies**: Understanding of file structure needed, document creation script completed (if applicable)
  - **Guide**: [Template Development Guide](../../guides/support/template-development-guide.md)
  - **Script**: `process-framework/scripts/file-creation/support/New-Template.ps1`
  - **Command**: `cd process-framework/scripts/file-creation/support && .\New-Template.ps1 -TemplateName "[Template Name]" -TemplateDescription "[Description]" -DocumentPrefix "[ID-PREFIX]" -DocumentCategory "[Category]"`
  - **Notes**: Template for files generated by the task (only needed if task creates new file types)

- [ ] **Task Usage Guide**: Create guide using New-Guide.ps1 and documentation-guide.md
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Dependencies**: Task definition and core infrastructure completed
  - **Guide**: [Documentation Guide](../../guides/05-validation/documentation-guide.md)
  - **Script**: `process-framework/scripts/file-creation/support/New-Guide.ps1`
  - **Command**: `cd process-framework/scripts/file-creation/support && .\New-Guide.ps1 -GuideTitle "framework-blueprint-sync-task-creation Usage Guide" -SubDirectory "[phase-directory]" -GuideDescription "Comprehensive guide for using the framework-blueprint-sync-task-creation task effectively"`
  - **Notes**: Explains how to use the task effectively, always needed for new tasks

### Phase 4: Documentation and Visualization (Session 4)

**Priority**: MEDIUM - Needed for complete task integration

- [ ] **Documentation Map Update**: Update PF-documentation-map.md with all new artifacts

  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Dependencies**: All previous phases completed, all artifacts created
  - **File**: `process-framework/PF-documentation-map.md`
  - **Artifacts to Add**: [List all new files created: task definition, scripts, templates, guides, context map]
  - **Notes**: Register all new artifacts and their relationships in the documentation map

- [ ] **Context Map Visualization**: Create context map visualization for the task
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Dependencies**: Task definition completed, all components identified
  - **Guide**: [Visualization Creation Guide](../../guides/support/visualization-creation-guide.md)
  - **Script**: process-framework/scripts/file-creation/02-design/New-ContextMap.ps1
  - **Template**: [Context Map Template](context-map-template.md)
  - **Command**: `cd process-framework/scripts/file-creation/02-design && .\New-ContextMap.ps1 -TaskName "framework-blueprint-sync-task-creation" -WorkflowPhase "[phase]" -MapDescription "Context map for framework-blueprint-sync-task-creation task"`
  - **Notes**: Shows component relationships and context requirements for the task

### Phase 5: Framework Evaluation (Separate Session)

**Priority**: HIGH - Must complete before new task can be used in production

- [ ] **Framework Evaluation**: Run [Framework Evaluation](../../tasks/support/framework-evaluation.md) (PF-TSK-062) targeting the new task to validate completeness, consistency, and integration quality
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Dependencies**: All previous phases completed — task definition, templates, guides, scripts, context map, and documentation updates finalized
  - **Notes**: This is a mandatory quality gate. The new task must not be used in production workflows until Framework Evaluation passes. Run as a dedicated session.

## Session Tracking

### Session 1: [YYYY-MM-DD]

**Focus**: [Session focus]
**Completed**:

- [List completed items]

**Issues/Blockers**:

- [List any issues encountered]

**Next Session Plan**:

- [Plan for next session]

### Session 2: [YYYY-MM-DD]

**Focus**: [Session focus]
**Completed**:

- [List completed items]

**Issues/Blockers**:

- [List any issues encountered]

**Next Session Plan**:

- [Plan for next session]

## Placeholder Components Created

### Templates with PLACEHOLDER Status

| Template           | Location | Placeholder Content | Implementation Priority |
| ------------------ | -------- | ------------------- | ----------------------- |
| [template-name.md] | [path]   | [Brief description] | [HIGH/MEDIUM/LOW]       |

### Guides with PLACEHOLDER Status

| Guide           | Location | Placeholder Content | Implementation Priority |
| --------------- | -------- | ------------------- | ----------------------- |
| [guide-name.md] | [path]   | [Brief description] | [HIGH/MEDIUM/LOW]       |

### Scripts with PLACEHOLDER Status

| Script            | Location | Placeholder Content | Implementation Priority |
| ----------------- | -------- | ------------------- | ----------------------- |
| [script-name.ps1] | [path]   | [Brief description] | [HIGH/MEDIUM/LOW]       |

## State File Updates Required

Track which state files need updates as components are implemented:

- [ ] **Documentation Map**: Add new artifacts

  - **Status**: [PENDING/COMPLETED]
  - **Items to Add**: [List items]

- [ ] **AI Tasks Registry**: Add new task
  - **Status**: [PENDING/COMPLETED]
  - **Task Entry**: [Task details]

## Completion Criteria

This temporary state file can be moved to `process-framework-local/state-tracking/temporary/old` when:

- [ ] All HIGH priority components are implemented (not placeholders)
- [ ] Task definition is complete and functional
- [ ] All state files are updated
- [ ] Documentation map reflects all new artifacts
- [ ] Framework Evaluation (PF-TSK-062) completed for the new task
- [ ] Feedback forms are completed for the task creation process

## Findings: LinkWatcher test/ vs FrameworkBuilder/appdev/test/

Comparison performed 2026-05-05. Both trees share the same top-level layout (`TE-documentation-map.md`, `TE-id-registry.json`, `archive/`, `audits/`, `automated/`, `e2e-acceptance-testing/`, `specifications/`, `state-tracking/`). Differences below are framework-level structural drift in the blueprint, not project-specific content.

### Drift items to sync (FrameworkBuilder is missing)

1. **`audits/e2e/` and `audits/performance/` subdirectories** — LinkWatcher uses these for `PF-TSK-030 -TestType E2E` and `-TestType Performance` audit reports. Templates exist in framework but blueprint has no landing dirs.

2. **`audits/<category>/old/` archive subdirectories** — LinkWatcher keeps superseded audit reports under `audits/{foundation,authentication,core-features,performance}/old/`. Blueprint has no equivalent convention.

3. **`state-tracking/audit/` directory** — LinkWatcher has multi-session audit-round tracking files (created by `New-AuditTracking.ps1`, template `audit-tracking-template.md`). Blueprint has only `permanent/` and `temporary/` siblings; missing `audit/`.

4. **`TE-id-registry.json` schema gaps** in blueprint:
   - Missing `BM` prefix (Performance Benchmarks, Levels 1–2) — required by 4-level performance testing methodology; consumed by `New-PerformanceTestEntry.ps1`
   - Missing `PH` prefix (Performance Scale/Resource, Levels 3–4)
   - Missing `id_gaps_policy` metadata field
   - `TE-TAR.directories` only lists `foundation/authentication/core-features/main`; missing `e2e` and `performance`
   - **Impact**: a fresh project scaffolded today would fail when the performance-and-e2e-test-scoping task tries to register a benchmark.

5. **`TE-documentation-map.md` missing sections** in blueprint:
   - No `audits/performance/` or `audits/e2e/` headings
   - `state-tracking/permanent` section omits `performance-test-tracking.md` (even though the file is bootstrapped into the same directory by current scaffolder)

### Project-specific content correctly absent from blueprint

For reference (do NOT propagate these to blueprint): `automated/parsers/`, `automated/fixtures/`, `automated/__init__.py`, `automated/conftest.py`, `automated/utils.py`, root-level `automated/test_*.py`, populated audit reports / test specs / e2e templates / workspace files, `archive/test-registry-archived-2026-03-26.yaml`, all `__pycache__/`.

## Architectural Decision: Thin Scaffolder + Authoritative Blueprint

**Decision**: keep `New-TestInfrastructure.ps1` (and analogous scaffolders) but make the blueprint the source of truth for *structure*. Scaffolder shrinks to ~50 lines responsible only for project-specific wiring.

**Split of responsibilities**:

- **Blueprint owns** (in `FrameworkBuilder/appdev/`): all directory structures, all README files, doc-maps, ID registries, gitignore files, tracker file shapes, configuration templates, framework code/scripts.
- **Scaffolder owns**:
  - Copying blueprint into target project location
  - Project-name substitution (`{{PROJECT_NAME}}` and similar placeholders)
  - Language-specific file selection (e.g., `conftest.py` for Python vs `jest.config.js` for JS) driven by `languages-config/{language}/`
  - Optional merge of `.gitignore` if target project already has one
  - Idempotency / safe re-run when adding to existing project

**Why not full retirement**: scaffolder still earns its keep on multi-language support and project-name substitution. Pure copy-blueprint approach loses both. If multi-language support is later abandoned, full retirement becomes viable.

## Implementation Plan: 5 Drift Items

These do NOT execute in this temp state's session — they execute under the new support task once it exists. The findings here are this temp state's deliverable; the IMPs are queued work for the new task.

> ✅ **All 5 items synced 2026-05-05** under PF-TSK-087 framework-blueprint-sync (session PF-STA-104). See `FrameworkBuilder/appdev/sync-log.md` for the entry.

| # | Change | Target File / Dir | Also update? | Status |
|---|--------|-------------------|--------------|--------|
| 1 | Add `audits/e2e/` and `audits/performance/` | `FrameworkBuilder/appdev/test/audits/` | Possibly scaffolder dir-creation list | ✅ SYNCED 2026-05-05 |
| 2 | Add `audits/<category>/old/` archive convention | All four category subdirs in blueprint | Document in `audits/README.md` | ✅ SYNCED 2026-05-05 |
| 3 | Add `state-tracking/audit/` directory | `FrameworkBuilder/appdev/test/state-tracking/` | Possibly scaffolder dir-creation list | ✅ SYNCED 2026-05-05 |
| 4 | Add `BM`, `PH` prefixes; `id_gaps_policy`; extra `TE-TAR.directories` entries | `FrameworkBuilder/appdev/test/TE-id-registry.json` AND `process-framework/templates/03-testing/TE-id-registry-template.json` (LinkWatcher) | Both must agree; sync may also flow this back | ✅ SYNCED 2026-05-05 |
| 5 | Add missing sections to test doc-map | `FrameworkBuilder/appdev/test/TE-documentation-map.md` | None (single source) | ✅ SYNCED 2026-05-05 |

## Open questions for the new task design

- **Direction of sync**: project → blueprint only, or also blueprint → project (back-propagating blueprint fixes to existing projects)? User stated "project → blueprint" only for now.
- **Detection**: how does the user/agent know what has drifted? Manual diff between project and blueprint? Periodic comparison report? Per-PR check?
- **Conflict handling**: what if two projects evolved the same blueprint area in incompatible ways?
- **Validation**: after applying changes to blueprint, what verifies the blueprint is still self-consistent? (e.g., new ID prefix added but no template referencing it).
- **Framework selection**: how is the target framework variant identified? Path? Registry lookup against `Framework_Registry.json`? Both?

## Key Decisions Made

- **2026-05-05** — Use thin scaffolder + authoritative blueprint (rationale above). Reject full scaffolder retirement due to multi-language and project-name substitution needs.
- **2026-05-05** — Improvements happen at project level; sync is a deliberate pull-back, not automatic. Blueprint stays one sync behind reality by design — gives evolutions time to prove themselves before becoming canon.
- **2026-05-05** — New task scope is all top-level framework directories, not limited to `test/`. Comparison-then-apply is the same workflow regardless of which subdir drifted.

## Future Considerations

- If a second real project ever exists alongside LinkWatcher, sync workflow will need to handle merging contributions from multiple sources.
- Once thin scaffolder is in place, may want analogous blueprints for `doc/` and `process-framework-local/` skeletons.
- Framework Evaluation (PF-TSK-079) might want a check that the blueprint and its scaffolder agree on directory list and required files.
