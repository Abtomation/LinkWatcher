---
id: PD-STA-065
type: Product Documentation
category: State Tracking
version: 1.0
created: 2026-03-27
updated: 2026-03-27
---

# Feature Request Tracking

This file tracks incoming product feature requests and enhancements. It serves as an intake queue for the [Feature Request Evaluation](../../../process-framework/tasks/01-planning/feature-request-evaluation.md) task (PF-TSK-067), which classifies each request and routes it to the correct workflow.

> **Scope**: This file tracks **product** feature requests only. Process framework improvements belong in [process-improvement-tracking.md](../../../process-framework-local/state-tracking/permanent/process-improvement-tracking.md).

## Status Legend

| Status | Description |
|--------|-------------|
| 📥 Submitted | Request documented, awaiting Feature Request Evaluation (PF-TSK-067) |
| ✅ Completed | Classified and routed — see Classification column and Notes for destination |
| ❌ Rejected | Evaluated but determined not to proceed |
| ⏸️ Deferred | Postponed to a later time |

## Classification Legend

| Classification | Meaning | What happens next |
|----------------|---------|-------------------|
| New Feature | Request is a new, independent feature | New entry added to [feature-tracking.md](feature-tracking.md) + feature state file created. Standard workflow applies (Tier Assessment → Design → Implementation). |
| Enhancement | Request enhances an existing feature | Enhancement State Tracking File created in `state-tracking/temporary/`. Target feature set to "🔄 Needs Enhancement" in feature-tracking.md. [Feature Enhancement](../../../process-framework/tasks/04-implementation/feature-enhancement.md) (PF-TSK-068) executes the work. |

## Active Feature Requests

| ID | Source | Description | Feature | Classification | Status | Last Updated | Notes |
|----|--------|-------------|---------|----------------|--------|--------------|-------|
| PD-FRQ-001 | [Tools Review 2026-03-26](../../../process-framework-local/feedback/reviews/tools-review-20260326.md) | Add HTML comment filtering to link validator (--skip-comments) to exclude links inside <\!-- --> blocks from broken link counts | — | — | 📥 Submitted | 2026-03-27 | ~180 false positives from commented-out links inflate triage effort. Migrated from PF-IMP-216. |
| PD-FRQ-002 | [Tools Review 2026-03-26](../../../process-framework-local/feedback/reviews/tools-review-20260326.md) | Add --summary flag to link validator for quick type-breakdown output without individual broken links | — | — | 📥 Submitted | 2026-03-27 | Requested in 2 bug-fixing forms. Would enable fast progress checks during bulk link fix sessions. Migrated from PF-IMP-217. |
| PD-FRQ-003 | [Tools Review 2026-03-31](../../../process-framework-local/feedback/reviews/tools-review-20260331-103941.md) | Create run.ps1 scripts for TE-E2E-001, TE-E2E-002, TE-E2E-003, TE-E2E-004 to convert manual E2E tests to fully automated scripted execution | — | — | 📥 Submitted | 2026-03-31 | Currently these 4 test cases require manual execution. All other tests are fully scripted. |
| PD-FRQ-004 | [Bug fix PD-BUG-090](doc/state-tracking/permanent/bug-tracking.md) | Session-scoped backup file management: restore, clean up, and preserve backups using a per-session ID to avoid conflicts with non-LinkWatcher .bak files | — | — | 📥 Submitted | 2026-04-14 | Discovered during PD-BUG-090 fix. **Core design**: Each LinkWatcher run generates a session ID (e.g., timestamp-based `lw-20260414-122316`). Backups use session-scoped suffix: `file.md.lw-20260414-122316.bak`. This ensures LinkWatcher backups are distinguishable from unrelated `.bak` files created by editors/IDEs/other tools. **Three capabilities**: (1) `--restore-backups [session-id]` — restore files from LinkWatcher backups for the current or specified session only, (2) `--clean-backups [session-id\|all]` — delete only LinkWatcher-created backups (identifiable by `lw-` prefix pattern), leaving unrelated `.bak` files untouched, (3) skip-if-exists per session — when the same file is updated multiple times in one session, preserve the initial backup so it reflects the true pre-session state. Multiple sessions' backups coexist without overwriting each other. |
| PD-FRQ-005 | PRJ-000 appdev — link-validation feedback | Per-folder project-root override for path resolution (template/blueprint folder support) | — | — | 📥 Submitted | 2026-05-16 | Today LinkWatcher uses a single --project-root for both file scanning and path resolution. Template folders (e.g., appdev/blueprint/, which ships to projects where it becomes their root) contain files whose absolute-from-host links (/process-framework/foo.md) are written from the rollout target's perspective and break when validated from the dev workspace's project-root. Proposed: a config key like 'path_resolution_overrides' that maps a folder (relative to project_root) to an effective base for path resolution. When validating files inside such a folder, absolute-from-host (and optionally at-prefix/standalone) targets resolve against <project_root>/<folder>/ instead of <project_root>/. Relative-from-source-dir resolution unchanged. Backward-compatible: no behavior change when the config key is absent. Implementation surface: validator.py _target_exists / _target_exists_at_root, plus settings.py LinkWatcherConfig. Use case in appdev (framework-builder): currently worked around via scripts/Convert-BlueprintLinks.py, which is a one-way rewrite that defeats the original link shape; this config would let blueprint files retain their target-layout link form without false-positive validation noise from appdev. |

## Completed Requests

<details>
<summary>Show completed requests (0 items)</summary>

| ID | Source | Description | Feature | Classification | Completed Date | Notes |
|----|--------|-------------|---------|----------------|----------------|-------|

</details>

## Update History

<details>
<summary>Show update history (4 entries)</summary>

| Date | Action | Updated By |
|------|--------|------------|
| 2026-03-27 | Added PD-FRQ-001: Add HTML comment filtering to link validator (--skip-comments) to exclude links inside <!-- --> blocks from broken link counts | AI Agent (PF-TSK-010) |
| 2026-03-27 | Added PD-FRQ-002: Add --summary flag to link validator for quick type-breakdown output without individual broken links | AI Agent (PF-TSK-010) |
| 2026-03-27 | Added PD-FRQ-003: User-facing documentation for 6.1.1 Link Validation feature | AI Agent (PF-TSK-007) |
| 2026-03-27 | Removed PD-FRQ-003: Superseded by dedicated user documentation task being created | AI Agent |
| 2026-03-31 | Added PD-FRQ-003: Create run.ps1 scripts for TE-E2E-001, TE-E2E-002, TE-E2E-003, TE-E2E-004 to convert manual E2E tests to fully automated scripted execution | AI Agent (PF-TSK-010) |
| 2026-04-14 | Added PD-FRQ-004: Session-scoped backup management with restore/cleanup/preserve-initial capabilities. Updated with session-ID design to avoid conflicts with non-LinkWatcher .bak files | AI Agent (PF-TSK-007) |
| 2026-05-16 | Added PD-FRQ-005: Per-folder project-root override for path resolution (template/blueprint folder support) | AI Agent (PF-TSK-010) |

</details>
