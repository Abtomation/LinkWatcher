---
id: PF-TEM-075
type: Process Framework
category: Template
version: 1.0
created: 2026-05-05
updated: 2026-05-05
task_name: [TASK-NAME]
---

# Session Temp State: framework-blueprint-sync — [Variant] — [YYYY-MM-DD]

> **⚠️ TEMPORARY FILE**: One-session inventory + selection tracker for a sync from a source project to `FrameworkBuilder/{variant}/`. Move to `process-framework-local/state-tracking/temporary/old/` after session ends. The durable record lives in the variant's `sync-backlog.md` and `sync-log.md`.

## Session Parameters

- **Task**: PF-TSK-087 framework-blueprint-sync
- **Source project**: [Project name] (`[absolute-path-to-source-project]`)
- **Target variant**: [variant] (`[absolute-path-to-FrameworkBuilder/{variant}/]`)
- **Scope**: [List in-scope top-level dirs, e.g., `process-framework/`, `process-framework-local/`, `doc/`, `test/`, `src/`, root files]
- **Sync backlog**: `FrameworkBuilder/[variant]/sync-backlog.md`
- **Sync log**: `FrameworkBuilder/[variant]/sync-log.md`
- **First sync**: [yes/no — if yes, note that backlog and log were created this session]

## Per-Item Classification & Selection (this session)

> **Rule column** values follow the [Per-Directory Handling Rules](/process-framework/tasks/support/framework-blueprint-sync-task.md#per-directory-handling-rules):
> `wholesale-replace` (process-framework/), `structure-only` (process-framework-local/), `per-item` (doc/, test/, root files), `skip-default` (src/).
>
> **Classification column** values: `SYNC` / `SKIP` / `ASK USER` / `RETAIN IN BLUEPRINT` / `PROTECT` / `NO ACTION`.
>
> **Status column** values: `PENDING` / `APPLIED` / `DEFERRED` / `REJECTED`.

| #     | Directory                  | Item                              | Rule              | Classification | Status  |
| ----- | -------------------------- | --------------------------------- | ----------------- | -------------- | ------- |
| PF-1  | `process-framework/`       | [Wholesale replace tree if in scope] | wholesale-replace | SYNC (auto)    | PENDING |
| PFL-1 | `process-framework-local/` | [structural addition or skeleton-file change] | structure-only    | [classification] | PENDING |
| DOC-1 | `doc/`                     | [item description]                | per-item          | [classification] | PENDING |
| TEST-1 | `test/`                   | [item description]                | per-item          | [classification] | PENDING |
| ROOT-1 | root                      | [file/path]                       | per-item          | [classification] | PENDING |

> Add/remove rows as needed. Group rows by directory; use a numeric suffix per directory (PF-1, PF-2, ...; DOC-1, DOC-2, ...).

## Notes on Specific Items

> One subsection per item that needs explanation, decision rationale, or sub-item breakdown. Reference items by ID (e.g., `### PF-1: process-framework/ wholesale replace`). Drop sections that don't apply.

### [ITEM-ID]: [Brief title]

- [Rationale, decisions, sub-items, or open questions]

## Session Log

### [YYYY-MM-DD] — Session 1

- [Created sync-backlog.md and sync-log.md at FrameworkBuilder/{variant}/ — only if first sync]
- [Walked both trees; full inventory above]
- [User decisions / corrections recorded]
- [Step in PF-TSK-087 reached at session end]

### [YYYY-MM-DD] — Session 2

- [If multi-session: continued sync work, items applied, blockers]

## Completion Criteria

This temporary state file can be moved to `process-framework-local/state-tracking/temporary/old/` when:

- [ ] User confirmed item selection at PF-TSK-087 Step 9 checkpoint
- [ ] Approved changes applied per directory rule (PF-TSK-087 Step 10)
- [ ] Blueprint internal consistency validated (PF-TSK-087 Step 11)
- [ ] `sync-backlog.md` updated (synced items resolved; deferred items retained)
- [ ] `sync-log.md` entry appended
- [ ] Source-project tracking updated if applicable (temp state, IMPs marked synced)
- [ ] This temp state moved to `temporary/old/`
- [ ] Feedback form (PF-TSK-087) completed
