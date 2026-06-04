---
id: PF-STA-104
type: Document
category: General
version: 1.0
created: 2026-05-05
updated: 2026-05-05
task_name: framework-blueprint-sync-appdev-20260505
---

# Session Temp State: framework-blueprint-sync — appdev — 2026-05-05

> **⚠️ TEMPORARY FILE**: One-session inventory + selection tracker for the first sync from LinkWatcher → FrameworkBuilder/appdev/. Move to `process-framework-local/state-tracking/temporary/old/` after session ends. The durable record lives in the variant's `sync-backlog.md` and `sync-log.md`.
>
> **Note**: Created via `New-TempTaskState.ps1 -Variant TaskCreation` (the only variant available; the file content is for sync session, not task creation).

## Session Parameters

- **Task**: PF-TSK-087 framework-blueprint-sync
- **Source project**: LinkWatcher (`C:/Users/ronny/VS_Code/LinkWatcher/`)
- **Target variant**: appdev (`C:/Users/ronny/VS_Code/FrameworkBuilder/appdev/`)
- **Scope**: All top-level dirs (`process-framework/`, `process-framework-local/`, `doc/`, `test/`, `src/`, root files)
- **Sync backlog**: `FrameworkBuilder/appdev/sync-backlog.md`
- **Sync log**: `FrameworkBuilder/appdev/sync-log.md`
- **First sync**: yes — backlog and log just created

## Per-Item Classification & Selection (this session)

| # | Directory | Item | Rule | Classification | Status |
|---|-----------|------|------|----------------|--------|
| PF-1 | `process-framework/` | Wholesale replace tree from LinkWatcher | wholesale-replace | SYNC (auto) | PENDING |
| PFL-1 | `process-framework-local/` | PF-id-registry-local.json PF-STA description text | structure-only | ASK USER | PENDING |
| DOC-1 | `doc/` | Add `technical/database/{diagrams,migrations,schemas}/` scaffolding | per-item | SYNC (recommended) | PENDING |
| DOC-2 | `doc/` | Add `user/faq/.gitkeep` scaffolding | per-item | SYNC (recommended) | PENDING |
| DOC-3 | `doc/` | Blueprint has `pre-framework/quality-assessments/` (project doesn't) | per-item | RETAIN IN BLUEPRINT (recommended) | PENDING |
| DOC-4 | `doc/` | Blueprint has `technical-debt/{assessments,debt-items}/` (project only has `matrices/`) | per-item | RETAIN IN BLUEPRINT (recommended) | PENDING |
| TEST-1 | `test/` | Add `audits/e2e/`, `audits/performance/` dirs | per-item | SYNC | PENDING |
| TEST-2 | `test/` | Add `audits/<category>/old/` archive subdirs (4 categories) | per-item | SYNC | PENDING |
| TEST-3 | `test/` | Add `state-tracking/audit/` dir | per-item | SYNC | PENDING |
| TEST-4 | `test/` | Patch `TE-id-registry.json` (BM, PH prefixes; id_gaps_policy; TE-TAR.directories e2e/performance) | per-item | SYNC | PENDING |
| TEST-5 | `test/` | Patch `TE-documentation-map.md` (audits/e2e + audits/performance sections; performance-test-tracking entry) | per-item | SYNC | PENDING |
| ROOT-1 | root | `ratings.db` and `ratings.db.bak-*` in blueprint | per-item | **PROTECT** — cross-project ratings store, do not touch | NO ACTION |
| ROOT-2 | root | Add framework-general `.gitignore` (sanitized) | per-item | ASK USER | PENDING |
| ROOT-3 | root | Add framework-general `.pre-commit-config.yaml` | per-item | ASK USER | PENDING |
| ROOT-4 | root | Patch `CLAUDE.md` framework-general sections | per-item | SYNC PARTIAL (recommended) | PENDING |

## Notes on Specific Items

### PF-1: process-framework/ wholesale replace
- Project is canonical per directory rule.
- Pre-replace sanity grep confirmed 128 "LinkWatcher" mentions across 25 files inside `process-framework/`. Most are about LinkWatcher the *bundled tool* (in `process-framework/tools/linkWatcher/`), which is framework-general — those are correct. A small number reference LinkWatcher as a *project* in canonical examples; acceptable.
- No action other than wholesale copy. Tooling artifacts (`__pycache__/`, etc.) excluded.

### PFL-1: PF-STA description divergence
- LinkWatcher: "Process Framework - Project-Local State Tracking"
- Blueprint: "Process Framework - State Tracking (framework only)"
- Schema identical; all `nextAvailable` correctly = 1 in blueprint.
- Default if no decision: keep blueprint as-is.

### DOC-3, DOC-4: Blueprint-only directories
- These are framework scaffolding for tasks LinkWatcher hasn't yet exercised:
  - `pre-framework/quality-assessments/` — onboarding (PF-TSK-064/065/066)
  - `technical-debt/{assessments,debt-items}/` — Technical Debt Assessment outputs
- Recommendation: retain in blueprint as scaffolding.

### ROOT-1: ratings.db (CORRECTION)
- **User clarified**: `ratings.db` and its `.bak-*` files in the blueprint are the **canonical cross-project ratings store** (used by `feedback_db.py`). They are intentional. Do NOT delete.
- Removing this from sync action list. Sync-backlog updated to reflect protection status.

### ROOT-2, ROOT-3: New blueprint root files
- LinkWatcher has both `.gitignore` and `.pre-commit-config.yaml`.
- `.pre-commit-config.yaml` references `process-framework/scripts/validation/Check-GitObjectsLiteral.ps1` (framework-resident hook).
- Decision needed: add sanitized versions to blueprint, or skip? Default if no decision: skip both this session, leave as backlog.

### ROOT-4: CLAUDE.md sync sub-items
Framework-general edits to apply (preserving blueprint TODO placeholders for project-specific sections):
- (a) Update LinkWatcher tool start-script path: `LinkWatcher/start_linkwatcher_background.ps1` → `process-framework/tools/linkWatcher/start_linkwatcher_background.ps1`
- (b) Fix `templates/templates/` → `templates/` typo in directory tree comment
- (c) Add the "Before running any script, check its parameters first" guidance block (framework-general)
- (d) Do NOT propagate LinkWatcher Capabilities content (project-specific)

## Session Log

### 2026-05-05 — Session 1

- Created sync-backlog.md and sync-log.md at `FrameworkBuilder/appdev/`
- Walked both trees; full inventory above
- User correction: `ratings.db*` are protected cross-project artifacts — removed from sync action list
- Awaiting user confirmation at checkpoint (Step 9)

## Completion Criteria

- [ ] User confirmed item selection at checkpoint
- [ ] Approved changes applied per directory rule
- [ ] Blueprint internal consistency validated
- [ ] sync-backlog.md updated (synced items resolved; deferred items retained)
- [ ] sync-log.md entry appended
- [ ] PF-STA-103 (initial validation case) updated to mark 5 test/ items as synced
- [ ] This temp state moved to `temporary/old/`
- [ ] Feedback form (PF-TSK-087) completed
