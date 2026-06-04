---
id: PF-STA-105
type: Document
category: General
version: 1.0
created: 2026-05-06
updated: 2026-05-06
task_name: appdev-20260506
---

# Session Temp State: framework-blueprint-sync — appdev — 2026-05-06

> **⚠️ TEMPORARY FILE**: One-session inventory + selection tracker for a sync from a source project to `FrameworkBuilder/{variant}/`. Move to `process-framework-local/state-tracking/temporary/old/` after session ends. The durable record lives in the variant's `sync-backlog.md` and `sync-log.md`.

## Session Parameters

- **Task**: PF-TSK-087 framework-blueprint-sync
- **Source project**: LinkWatcher (`c:\Users\ronny\VS_Code\LinkWatcher`)
- **Target variant**: appdev (`C:\Users\ronny\VS_Code\FrameworkBuilder\appdev`)
- **Scope**: `process-framework/`, `process-framework-local/`, `doc/`, `test/`, root files
- **Sync backlog**: `FrameworkBuilder/appdev/sync-backlog.md`
- **Sync log**: `FrameworkBuilder/appdev/sync-log.md`
- **First sync**: no — second sync (initial sync was 2026-05-05)

## Per-Item Classification & Selection (this session)

> **Rule column** values follow the [Per-Directory Handling Rules](/process-framework/tasks/support/framework-blueprint-sync-task.md#per-directory-handling-rules):
> `wholesale-replace` (process-framework/), `structure-only` (process-framework-local/), `per-item` (doc/, test/, root files), `skip-default` (src/).
>
> **Classification column** values: `SYNC` / `SKIP` / `ASK USER` / `RETAIN IN BLUEPRINT` / `PROTECT` / `NO ACTION`.
>
> **Status column** values: `PENDING` / `APPLIED` / `DEFERRED` / `REJECTED`.

| #     | Directory                  | Item                                                                                        | Rule              | Classification | Status  |
| ----- | -------------------------- | ------------------------------------------------------------------------------------------- | ----------------- | -------------- | ------- |
| PF-1  | `process-framework/`       | Wholesale replace entire tree (many committed and working-tree changes since 2026-05-05)    | wholesale-replace | SYNC (auto)    | APPLIED |
| PFL-1 | `process-framework-local/` | `PF-id-registry-local.json` PF-STA description text alignment                              | structure-only    | ASK USER       | APPLIED |
| PFL-2 | `process-framework-local/` | `process-improvement-tracking.md` blueprint extra `## Update History` section (REMOVE)      | structure-only    | SYNC           | APPLIED |
| DOC-1 | `doc/`                     | No new structural drift (already covered in 2026-05-05 addendums)                          | per-item          | NO ACTION      | APPLIED |
| TEST-1 | `test/`                   | No new structural drift (already covered in 2026-05-05 addendums)                          | per-item          | NO ACTION      | APPLIED |
| ROOT-1 | root                      | `CLAUDE.md` "LinkWatcher Workflow" inaccurate — replace with project's "LinkWatcher Capabilities" content | per-item          | SYNC           | APPLIED |
| ROOT-2 | root                      | `.gitignore` add framework-general version to blueprint                                     | per-item          | ASK USER       | APPLIED |
| ROOT-3 | root                      | `.pre-commit-config.yaml` add to blueprint (Python tooling + framework-resident hooks)      | per-item          | ASK USER       | APPLIED |
| ROOT-P | root                      | `ratings.db` + `ratings.db.bak-*` — protected cross-project ratings store                  | per-item          | PROTECT        | NO ACTION |

## Notes on Specific Items

### PF-1: process-framework/ wholesale replace

Many changes since 2026-05-05 in working tree (24 modified files) plus a commit (`208b7bd`) that touched dozens of framework scripts/guides/tasks/templates. Notable additions in working tree:

- New: `process-framework/tasks/support/framework-blueprint-sync-task.md` (this task)
- New: `process-framework/templates/support/temp-blueprint-sync-state-template.md`
- New: `process-framework/guides/support/blueprint-sync-consideration-policy-guide.md`
- Modified: many script/guide/task refinements

Per directory rule: full tree copy (delete-then-copy), exclude `__pycache__/`. Counters in `PF-id-registry.json` will be reset on next project initialization.

### PFL-1: PF-STA description wording

Project's PF-STA description: "Process Framework - Project-Local State Tracking"
Blueprint's PF-STA description: "Process Framework - State Tracking (framework only)"

Schema is identical. Project wording is more accurate (PF-STA is project-local, not framework-only). Awaiting user decision on whether to align.

### PFL-2: Remove blueprint's stale Update History section

Blueprint's `process-improvement-tracking.md` has lines 82-92:

```
## Update History

<details>
<summary>Show update history (681 entries)</summary>

| Date | Change | Updated By |
| --- | --- | --- |

</details>
```

Project has no such section (file ends at "Tasks That Update This File"). The "(681 entries)" text is misleading project-history residue. Recommendation: REMOVE the section from the blueprint to match the project's current skeleton structure.

### ROOT-1: CLAUDE.md LinkWatcher section

Blueprint's "LinkWatcher Workflow" section (4 lines) is **inaccurate**:
- Claims "LinkWatcher updates all markdown links in real-time" — actually updates 24 monitored extensions including `.py`, `.ps1`, `.psm1`, `.yaml`, `.json`, `.dart`, etc.
- This causes downstream agents to assume LinkWatcher only handles markdown.

Project's "LinkWatcher Capabilities" section accurately describes the bundled tool's behavior. It IS framework-general (LinkWatcher ships with the framework as a tool in `process-framework/tools/linkWatcher/`).

Sync action: replace blueprint's "LinkWatcher Workflow" section with project's "LinkWatcher Capabilities" section content, but:
- Drop the `> **Full reference**: @doc/user/handbooks/linkwatcher-capabilities-reference.md` line (project-specific path)
- Keep all the framework-general capability description

### ROOT-2: .gitignore

Project file is 147 lines. Almost entirely framework-general:
- Lines 1-136: standard Python/IDE/OS gitignore conventions
- Lines 137-146: framework-tool entries — `*.log`, `test_output/`, `temp/`, `.linkwatcher.lock`, `process-framework-local/tools/linkWatcher/logs/`, `process-framework-local/tools/linkWatcher/LinkWatcherBrokenLinks.txt`, `process-framework-local/feedback/ratings.db`, `test/state-tracking/permanent/performance-results.db` — all framework-general (about the bundled LinkWatcher tool, ratings DB, performance DB)

Only entry that's not strictly framework-general: `.linkwatcher/dependency_graph.png` (likely tool-generated artifact). All others belong in any project using the framework.

Awaiting user decision: copy project's `.gitignore` to blueprint as-is, copy and lightly clean (drop `.linkwatcher/dependency_graph.png`), or skip?

### ROOT-3: .pre-commit-config.yaml

Project file is 47 lines. Mix of:
- Lines 1-30: standard pre-commit hooks + Python tooling (black, isort, flake8). Python-specific.
- Lines 32-47: framework-resident hooks
  - `pytest-quick` → `process-framework/scripts/test/Run-Tests.ps1 -Quick`
  - `no-git-objects-literal` → `process-framework/scripts/validation/Check-GitObjectsLiteral.ps1` (PF-IMP-615)

Both framework-resident hooks are 100% framework-general (scripts ship in process-framework/, the .git/objects literal corruption guard applies to any project).

The Python-specific hooks (black/isort/flake8) are language-specific. Since `appdev` is the general appdev variant, blanket Python may not fit all projects.

Awaiting user decision: copy as-is (Python-flavored), copy with placeholder for language-specific tooling, or skip?

### ROOT-P: Protected DB files

Per [Known Protected Artifacts](/process-framework/tasks/support/framework-blueprint-sync-task.md#known-protected-artifacts-root-files): `ratings.db` and `ratings.db.bak-*` are the canonical cross-project ratings store. No action — sync inspects only.

## Session Log

### 2026-05-06 — Session 1

- Backlog and sync-log already exist (created 2026-05-05). This is the second sync session.
- Walked source project + blueprint trees with deep comparison of skeleton files (per Coverage note from 2026-05-05).
- Found 3 new drift items: PFL-2 (blueprint's stale Update History section), ROOT-1 (CLAUDE.md inaccurate LinkWatcher section).
- Backlog updated with new items 2026-05-06.
- Session inventory ready for user checkpoint at PF-TSK-087 Step 9.

## Completion Criteria

This temporary state file can be moved to `process-framework-local/state-tracking/temporary/old/` when:

- [x] User confirmed item selection at PF-TSK-087 Step 9 checkpoint
- [x] Approved changes applied per directory rule (PF-TSK-087 Step 10)
- [x] Blueprint internal consistency validated (PF-TSK-087 Step 11)
- [x] `sync-backlog.md` updated (synced items resolved; deferred items retained)
- [x] `sync-log.md` entry appended
- [x] Source-project tracking updated if applicable (temp state, IMPs marked synced)
- [x] This temp state moved to `temporary/old/`
- [x] Feedback form (PF-TSK-087) completed
