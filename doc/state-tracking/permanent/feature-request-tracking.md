---
id: PD-STA-065
type: Product Documentation
category: State Tracking
version: 1.0
created: 2026-03-27
updated: 2026-06-10
---

# Feature Request Tracking

This file tracks incoming product feature requests and enhancements. It serves as an intake queue for the [Feature Request Evaluation](../../../process-framework/tasks/01-planning/feature-request-evaluation.md) task (PF-TSK-067), which classifies each request and routes it to the correct workflow.

> **Scope**: This file tracks **product** feature requests only. Process framework improvements belong in [process-improvement-tracking.md](appdev/process-framework-central/state-tracking/permanent/process-improvement-tracking.md).

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
| PD-FRQ-001 | [Tools Review 2026-03-26](appdev/process-framework-central/feedback/reviews/tools-review-20260326.md) | Add HTML comment filtering to link validator (--skip-comments) to exclude links inside <\!-- --> blocks from broken link counts | — | — | 📥 Submitted | 2026-03-27 | ~180 false positives from commented-out links inflate triage effort. Migrated from PF-IMP-216. |
| PD-FRQ-002 | [Tools Review 2026-03-26](appdev/process-framework-central/feedback/reviews/tools-review-20260326.md) | Add --summary flag to link validator for quick type-breakdown output without individual broken links | — | — | 📥 Submitted | 2026-03-27 | Requested in 2 bug-fixing forms. Would enable fast progress checks during bulk link fix sessions. Migrated from PF-IMP-217. |
| PD-FRQ-003 | [Tools Review 2026-03-31](appdev/process-framework-central/feedback/reviews/tools-review-20260331-103941.md) | Create run.ps1 scripts for TE-E2E-001, TE-E2E-002, TE-E2E-003, TE-E2E-004 to convert manual E2E tests to fully automated scripted execution | — | — | ❌ Rejected | 2026-06-08 | Currently these 4 test cases require manual execution. All other tests are fully scripted.. Not a product feature request — test-execution infrastructure (tech debt), no feature assignment. Already satisfied: run.ps1 scripts exist for TE-E2E-001 through 004, scripted execution passed 2026-05-04 via Run-E2EAcceptanceTest.ps1. |
| PD-FRQ-004 | [Bug fix PD-BUG-090](doc/state-tracking/permanent/bug-tracking.md) | Session-scoped backup file management: restore, clean up, and preserve backups using a per-session ID to avoid conflicts with non-LinkWatcher .bak files | — | — | 📥 Submitted | 2026-04-14 | Discovered during PD-BUG-090 fix. **Core design**: Each LinkWatcher run generates a session ID (e.g., timestamp-based `lw-20260414-122316`). Backups use session-scoped suffix: `file.md.lw-20260414-122316.bak`. This ensures LinkWatcher backups are distinguishable from unrelated `.bak` files created by editors/IDEs/other tools. **Three capabilities**: (1) `--restore-backups [session-id]` — restore files from LinkWatcher backups for the current or specified session only, (2) `--clean-backups [session-id\|all]` — delete only LinkWatcher-created backups (identifiable by `lw-` prefix pattern), leaving unrelated `.bak` files untouched, (3) skip-if-exists per session — when the same file is updated multiple times in one session, preserve the initial backup so it reflects the true pre-session state. Multiple sessions' backups coexist without overwriting each other. |
| PD-FRQ-007 | [Framework Evaluation PF-EVR-025](appdev/process-framework-central/evaluation-reports/20260610-framework-evaluation-release-and-rollout-end-to-end.md) | Deploy user handbooks with the global install: add doc/user/handbooks/ to install_global.py core_dirs (-> ~/bin/docs/), update release-process.md 'What Gets Deployed' table + release checklist. Gives the 8 handbooks a release channel and makes the per-project config template's pointer (<install>/doc/user/handbooks/configuration-guide.md) resolve on every machine - it is currently dead everywhere outside the source repo. | — | — | ❌ Rejected | 2026-06-10 | X-3 in PF-EVR-025. Several handbooks are primarily downstream-facing (multi-project-setup, capabilities-reference, file-type troubleshooting). Framework-side follow-up PF-IMP-1093 (blueprint pointer + CLAUDE.md references + snapshot migrations) is Deferred until this ships.. Evaluated via PF-TSK-067 (2026-06-10): not classified as feature/enhancement - no active feature owns deployment/ (5.1.1/5.1.6 archived). Routed as bug PD-BUG-104 (dead handbook pointer on deployed machines = user-visible defect); fix deploys doc/user/handbooks/ via install_global.py core_dirs + release-process.md updates. Framework follow-up PF-IMP-1093 remains deferred until fix ships in a release. |
| PD-FRQ-008 | [Tools Review 2026-06-16 (appdev PRJ-000)](appdev/process-framework-central/feedback/reviews/tools-review-20260616-113820.md) | LinkWatcher validation report has no suppressed-by-rule count: after adding an ignore rule the report shows the lower broken-link total but not how many links each rule suppressed, leaving ignore-rule blind spots invisible in the summary. Add a per-rule suppressed-link count to the validation summary. | — | — | 📥 Submitted | 2026-06-16 | Cross-filed from appdev (PRJ-000) Tools Review 2026-06-16; observed in a PF-TSK-009 session (PF-FEE-1319) running LinkWatcher --validate on appdev. Routed as a product feature request per the originating form's routing note. For PRJ-001's own triage. |
| PD-FRQ-009 | [Tools Review 2026-06-16 (appdev PRJ-000)](appdev/process-framework-central/feedback/reviews/tools-review-20260616-113820.md) | LinkWatcher scan descends into Windows directory junctions/reparse points (os.walk follows them because DirEntry.is_symlink() is False for junctions), double-scanning junctioned trees - a stale rollback-worktree junction produced 939 duplicate broken-link entries. Skip directory junctions/reparse points during scans. | — | — | 📥 Submitted | 2026-06-16 | Cross-filed from appdev (PRJ-000) Tools Review 2026-06-16; observed in a PF-TSK-009 session (PF-FEE-1319). Robustness enhancement to scan behavior - PRJ-001 may reclassify as a bug at triage. Symptom source in appdev (stale .rollback-worktree) is separately tracked as PF-IMP-1147; this is the durable product-side fix. |
| PD-FRQ-010 | Cross-project finding (appdev PF-IMP-1227b) | Add a one-line note to the Release Process Guide (doc/ci-cd/release-process.md) that install_global.py is idempotent/rerunnable after clearing a blocker, so a partial install (files copied, venv step failed) has a documented resume-vs-rerun answer instead of improvising. | — | — | 📥 Submitted | 2026-06-16 | Filed cross-project from appdev (PRJ-000) during the PF-TSK-009 fast-track batch. Originated as PF-IMP-1227 part (b): the agnostic Release & Deployment task (PF-TSK-008) delegates deploy mechanics to this project's Release Process Guide, so this resume guidance belongs here, not in the framework task. Related installer bugs PD-BUG-106/110 already filed. |
## Completed Requests

<details>
<summary>Show completed requests (1 items)</summary>

| ID | Source | Description | Feature | Classification | Completed Date | Notes |
|----|--------|-------------|---------|----------------|----------------|-------|
| PD-FRQ-005 | PRJ-000 appdev — link-validation feedback | Per-folder project-root override for path resolution (template/blueprint folder support) | 6.1.1 | Enhancement | 2026-06-04 | Today LinkWatcher uses a single --project-root for both file scanning and path resolution. Template folders (e.g., appdev/blueprint/, which ships to projects where it becomes their root) contain files whose absolute-from-host links (/process-framework/foo.md) are written from the rollout target's perspective and break when validated from the dev workspace's project-root. Proposed: a config key like 'path_resolution_overrides' that maps a folder (relative to project_root) to an effective base for path resolution. When validating files inside such a folder, absolute-from-host (and optionally at-prefix/standalone) targets resolve against <project_root>/<folder>/ instead of <project_root>/. Relative-from-source-dir resolution unchanged. Backward-compatible: no behavior change when the config key is absent. Implementation surface: validator.py _target_exists / _target_exists_at_root, plus settings.py LinkWatcherConfig. Use case in appdev (framework-builder): currently worked around via scripts/Convert-BlueprintLinks.py, which is a one-way rewrite that defeats the original link shape; this config would let blueprint files retain their target-layout link form without false-positive validation noise from appdev.. Enhancement to Link Validation (validation-only): path_resolution_overrides config field + validator resolution. Framework config-loading wiring + consumer config tracked separately (see state file Dependent work row). |

</details>

## Update History

<details>
<summary>Show update history (13 entries)</summary>

| Date | Action | Updated By |
|------|--------|------------|
| 2026-03-27 | Added PD-FRQ-001: Add HTML comment filtering to link validator (--skip-comments) to exclude links inside <!-- --> blocks from broken link counts | AI Agent (PF-TSK-010) |
| 2026-03-27 | Added PD-FRQ-002: Add --summary flag to link validator for quick type-breakdown output without individual broken links | AI Agent (PF-TSK-010) |
| 2026-03-27 | Added PD-FRQ-003: User-facing documentation for 6.1.1 Link Validation feature | AI Agent (PF-TSK-007) |
| 2026-03-27 | Removed PD-FRQ-003: Superseded by dedicated user documentation task being created | AI Agent |
| 2026-03-31 | Added PD-FRQ-003: Create run.ps1 scripts for TE-E2E-001, TE-E2E-002, TE-E2E-003, TE-E2E-004 to convert manual E2E tests to fully automated scripted execution | AI Agent (PF-TSK-010) |
| 2026-04-14 | Added PD-FRQ-004: Session-scoped backup management with restore/cleanup/preserve-initial capabilities. Updated with session-ID design to avoid conflicts with non-LinkWatcher .bak files | AI Agent (PF-TSK-007) |
| 2026-05-16 | Added PD-FRQ-005: Per-folder project-root override for path resolution (template/blueprint folder support) | AI Agent (PF-TSK-010) |
| 2026-06-04 | Classified PD-FRQ-005 as Enhancement (feature 6.1.1) — ✅ Completed | AI Agent (PF-TSK-067) |
| 2026-06-08 | Rejected PD-FRQ-003: Not a product feature request — test-execution infrastructure (tech debt), no feature assignment. Already satisfied: run.ps1 scripts exist for TE-E2E-001 through 004, scripted execution passed 2026-05-04 via Run-E2EAcceptanceTest.ps1. | AI Agent (PF-TSK-067) |
| 2026-06-08 | Added PD-FRQ-006: Add a release-process step that detects new/changed config-schema fields (settings.py / config-examples/linkwatcher-config.yaml) at release and emits a downstream-propagation signal so projects update their per-project tools/linkwatcher/linkwatcher-config.yaml. | AI Agent (PF-TSK-010) |
| 2026-06-09 | Removed PD-FRQ-006: implemented as PF-PRO-039 "Fork 1" in LinkWatcher's release process — config-schema propagation added to `install_global.py` (via `deployment/propagate_config_schema.py`): on a project-configurable schema change it files a high-priority IMP into central intake and syncs the appdev per-project config template. Not a product feature request; removed per request. | AI Agent |
| 2026-06-10 | Added PD-FRQ-007: Deploy user handbooks with the global install: add doc/user/handbooks/ to install_global.py core_dirs (-> ~/bin/docs/), update release-process.md 'What Gets Deployed' table + release checklist. Gives the 8 handbooks a release channel and makes the per-project config template's pointer (<install>/doc/user/handbooks/configuration-guide.md) resolve on every machine - it is currently dead everywhere outside the source repo. | AI Agent (PF-TSK-010) |
| 2026-06-10 | Rejected PD-FRQ-007: Evaluated via PF-TSK-067 (2026-06-10): not classified as feature/enhancement - no active feature owns deployment/ (5.1.1/5.1.6 archived). Routed as bug PD-BUG-104 (dead handbook pointer on deployed machines = user-visible defect); fix deploys doc/user/handbooks/ via install_global.py core_dirs + release-process.md updates. Framework follow-up PF-IMP-1093 remains deferred until fix ships in a release. | AI Agent (PF-TSK-067) |
| 2026-06-16 | Added PD-FRQ-008: LinkWatcher validation report has no suppressed-by-rule count: after adding an ignore rule the report shows the lower broken-link total but not how many links each rule suppressed, leaving ignore-rule blind spots invisible in the summary. Add a per-rule suppressed-link count to the validation summary. | AI Agent (PF-TSK-010) |
| 2026-06-16 | Added PD-FRQ-009: LinkWatcher scan descends into Windows directory junctions/reparse points (os.walk follows them because DirEntry.is_symlink() is False for junctions), double-scanning junctioned trees - a stale rollback-worktree junction produced 939 duplicate broken-link entries. Skip directory junctions/reparse points during scans. | AI Agent (PF-TSK-010) |
| 2026-06-16 | Added PD-FRQ-010: Add a one-line note to the Release Process Guide (doc/ci-cd/release-process.md) that install_global.py is idempotent/rerunnable after clearing a blocker, so a partial install (files copied, venv step failed) has a documented resume-vs-rerun answer instead of improvising. | AI Agent (PF-TSK-010) |

</details>
