---
id: PF-FST-001
description: "Tracks implementation status and documentation requirements for every feature across the project."
type: Process Framework
category: State Tracking
version: 2.1
created: 2023-06-15
updated: 2026-08-14
---

# LinkWatcher - Feature Tracking Document

This document tracks the implementation status and documentation requirements for all features in the LinkWatcher project.

> **Updating this file**: All mutations route through scripts so the Progress Summary stays in sync. Do not edit rows or the Progress Summary directly. See the [Feature Tracking Mutation Guide](../../../process-framework/guides/support/feature-tracking-mutation-guide.md) for the script for each mutation type.

> **v2.0 Note**: Consolidated from 42 granular features to 9 architectural-boundary-aligned features.
<details>
<summary><strong>📋 Table of Contents</strong></summary>

- [Status Legends](#status-legends)
- [Related Documents](#related-documents)
- [Feature Categories](#feature-categories)
  - [0. System Architecture & Foundation](#0-system-architecture--foundation)
  - [1. File Watching & Detection](#1-file-watching--detection)
  - [2. Link Parsing & Update](#2-link-parsing--update)
  - [3. Logging & Monitoring](#3-logging--monitoring)
  - [6. Link Validation & Reporting](#6-link-validation--reporting)
- [Archived Features](#archived-features)
- [Progress Summary](#progress-summary)

</details>

## Status Legends

### Implementation Status

| Symbol | Status                | Description                                                                           | Next Task |
| ------ | --------------------- | ------------------------------------------------------------------------------------- | --------- |
| ⬜     | Needs Assessment      | Feature added, needs complexity/tier assessment                                       | PF-TSK-067 |
| 📋     | Needs FDD             | Assessment done (Tier 2+), needs Functional Design Document                           | PF-TSK-027 |
| 🗄️     | Needs DB Design       | FDD done (or Assessment for T1), assessment marks DB design required, needs database schema | PF-TSK-021 |
| 🔌     | Needs API Design      | DB Design done (or not needed), assessment marks API design required, needs API specification | PF-TSK-020 |
| 🎨     | Needs UI Design       | API Design done (or not needed), assessment marks UI design required, needs UI/UX design document | PF-TSK-090 |
| 📜     | Needs Instruction Design | UI Design done (or not needed), assessment marks instruction design required, needs instruction design document | PF-TSK-094 |
| 📝     | Needs TDD             | All design tasks done, needs Technical Design Document                                | PF-TSK-015 |
| 🧪     | Needs Test Spec       | TDD done, needs test specification                                                    | PF-TSK-012 |
| 🔧     | Needs Impl Plan       | Test spec done, needs implementation planning                                         | PF-TSK-044 |
| 🟡     | In Progress           | Implementation plan created, work underway (detail in impl state file)                | Per impl state file |
| 👀     | Needs Review          | Implementation complete, needs code review                                            | PF-TSK-005 |
| 🔎     | Needs Test Scoping    | Code review passed, needs performance and E2E test needs identification               | PF-TSK-086 |
| 📖     | Needs User Docs       | Test scoping complete, feature has user-visible behavior needing documentation         | PF-TSK-081 |
| 🟢     | Completed             | All scoping and documentation complete (or not needed), feature fully complete         | — |
| 🔄     | Needs Enhancement     | Enhancement scoped, needs execution (see linked state file)                           | PF-TSK-068 |
| 🔬     | Needs Technical Exploration | Feature blocked on an open research question; the exploration is queued in technical-exploration-tracking.md. Divert-and-return: cleared back to the feature's pipeline status when the exploration resolves | PF-TSK-093 |

> **Design status branching**: After FDD (Tier 2+) or Assessment (Tier 1), the next status depends on the design-requirement flags recorded in the assessment document's Design Requirements Evaluation section. Order: DB Design first → API Design → UI Design → Instruction Design → TDD. If a design is not required, that status is skipped. Per-feature design artifact links live in each feature's state file `§4 Documentation Inventory` (per PF-PRO-002 / PF-IMP-760, not in master columns). ADRs are tracked cross-cuttingly in the [ADR Index](architecture-tracking.md#adr-index), not per-feature.

### Documentation Tier

| Symbol | Tier              | Documentation Required                         | Normalized Score Range |
| ------ | ----------------- | ---------------------------------------------- | ---------------------- |
| 🔵     | Tier 1 (Simple)   | Brief technical notes in task breakdown        | 1.0-1.6                |
| 🟠     | Tier 2 (Moderate) | FDD + Lightweight TDD focusing on key sections | 1.61-2.3               |
| 🔴     | Tier 3 (Complex)  | FDD + Complete TDD with all sections           | 2.31-3.0               |

### Test Status Legend

| Symbol | Status                     | Description                                                                 |
| ------ | -------------------------- | --------------------------------------------------------------------------- |
| ⬜     | No Tests                   | No test specifications exist for this feature                               |
| 🚫     | No Test Required           | Feature explicitly marked as not requiring tests                            |
| 📋     | Specs Created              | Test specifications exist but implementation not started                    |
| 🟡     | In Progress                | Some tests implemented, some pending                                        |
| 🔍     | Audit In Progress          | At least one test file is currently undergoing audit                        |
| 🟡     | Tests Partially Approved   | Some test files passed audit; others are still pending audit                |
| ✅     | All Passing                | All automated AND manual tests implemented and passing                      |
| 🔴     | Some Failing               | One or more tests are failing or failed audit                               |
| 🔧     | Automated Only             | Only automated tests exist; manual test cases not yet created               |
| 🔄     | Re-testing Needed          | Code changes or audit findings require test updates / re-execution          |

### Notes Column Convention

Brief free-text only. Do not duplicate information available elsewhere:
- **No links** — state file links are in the ID column, doc links are in dedicated columns
- **No dates** — dates are tracked in state files and git history
- **No status repetition** — the Status column already captures implementation state

Good: `On-demand broken link scanning with context-aware filtering. PD-BUG-051 open`
Bad: `See [state file](path). Updated 2026-04-01. Status: In Progress.`

### Priority Levels

| Priority | Description                             |
| -------- | --------------------------------------- |
| P1       | Critical - Must have for MVP            |
| P2       | High - Important for core functionality |
| P3       | Medium - Nice to have, improves experience |
| P4       | Low - Future consideration              |

## Related Documents

<details>
<summary><strong>Planning & Implementation Resources</strong></summary>

- [Process: Definition of Done](../../../process-framework/guides/04-implementation/definition-of-done.md): Clear criteria for when a feature is considered complete
- [Product: Feature Dependencies](../../technical/architecture/feature-dependencies.md): Auto-generated visual map and matrix of feature dependencies (run `Update-FeatureDependencies.ps1` to refresh)
- [Process: Technical Debt Tracker](technical-debt-tracking.md): System for tracking and managing technical debt
- [Process: Documentation Tier Assignments](../../documentation-tiers/README.md): Information about documentation tier assignments and assessment process
</details>

## Feature Categories

<details>
<summary><strong>0. System Architecture & Foundation</strong></summary>

### 0.0 System Architecture & Foundation

Foundation features that provide architectural foundations for the application.

|  ID  |  Feature  |  Status  |  Priority  |  Doc Tier  |  Test Status  |  Dependencies  |  Notes  |
|  --  |  -------  |  ------  |  --------  |  --------  |  -----------  |  ------------  |  -----  |
| [0.1.1](../features/0.1.1-core-architecture-implementation-state.md) | Core Architecture | 🟢 Completed | P1 | [🔴 Tier 3](../../documentation-tiers/assessments/PD-ASS-191-0-1-1-core-architecture.md) | 🔄 Re-testing Needed | — | **FOUNDATION** Service orchestrator, data models, path utilities, CLI entry point |
| [0.1.2](../features/0.1.2-in-memory-link-database-implementation-state.md) | In-Memory Link Database | 🟢 Completed | P1 | [🟠 Tier 2](../../documentation-tiers/assessments/PD-ASS-192-0-1-2-in-memory-link-database.md) | 🔄 Re-testing Needed | 0.1.1 | **FOUNDATION** Thread-safe, target-indexed link storage with O(1) lookups; TD163 resolved (2026-04-03): +14 tests, coverage 81%→93%, 57/57 passing. Audit: [TE-TAR-019](../../../test/audits/unit/0-system-architecture-foundation/0-0-system-architecture-foundation/audit-report-0-1-2-test-database.md) |
| [0.1.3](../features/0.1.3-configuration-system-implementation-state.md) | Configuration System | 🟢 Completed | P1 | [🔵 Tier 1](../../documentation-tiers/assessments/PD-ASS-193-0-1-3-configuration-system.md) | 🔄 Re-testing Needed | — | **FOUNDATION** Multi-source config loading, validation, environment presets |

</details>

<details>
<summary><strong>1. File Watching & Detection</strong></summary>

### 1.0 File Watching & Detection

Real-time file system monitoring and movement detection.

|  ID  |  Feature  |  Status  |  Priority  |  Doc Tier  |  Test Status  |  Dependencies  |  Notes  |
|  --  |  -------  |  ------  |  --------  |  --------  |  -----------  |  ------------  |  -----  |
| [1.1.1](../features/1.1.1-file-system-monitoring-implementation-state.md) | File System Monitoring | 🟢 Completed | P1 | [🟠 Tier 2](../../documentation-tiers/assessments/PD-ASS-194-1-1-1-file-system-monitoring.md) | 🔄 Re-testing Needed | 0.1.1 | Watchdog event handling, move detection, directory moves, file filtering |

</details>

<details>
<summary><strong>2. Link Parsing & Update</strong></summary>

### 2.0 Link Parsing & Update

Parser implementations for different file formats and link update mechanisms.

|  ID  |  Feature  |  Status  |  Priority  |  Doc Tier  |  Test Status  |  Dependencies  |  Notes  |
|  --  |  -------  |  ------  |  --------  |  --------  |  -----------  |  ------------  |  -----  |
| [2.1.1](../features/2.1.1-link-parsing-system-implementation-state.md) | Link Parsing System | 🟢 Completed | P1 | [🟠 Tier 2](../../documentation-tiers/assessments/PD-ASS-195-2-1-1-link-parsing-system.md) | 🔄 Re-testing Needed | 0.1.1 | Parser registry/facade with 7 format-specific parsers |
| [2.2.1](../features/2.2.1-link-updating-implementation-state.md) | Link Updating | 🟢 Completed | P1 | [🟠 Tier 2](../../documentation-tiers/assessments/PD-ASS-196-2-2-1-link-updating.md) | 🔄 Re-testing Needed | 0.1.1 | Reference updating with relative path calculation, atomic writes, dry-run mode — blueprint-aware reference updating; Test specification created: TE-TSP-046 (2026-08-10) |

</details>

<details>
<summary><strong>3. Logging & Monitoring</strong></summary>

### 3.0 Logging & Monitoring

Logging system and operational monitoring features.

|  ID  |  Feature  |  Status  |  Priority  |  Doc Tier  |  Test Status  |  Dependencies  |  Notes  |
|  --  |  -------  |  ------  |  --------  |  --------  |  -----------  |  ------------  |  -----  |
| [3.1.1](../features/3.1.1-logging-system-implementation-state.md) | Logging System | 🟢 Completed | P1 | [🟠 Tier 2](../../documentation-tiers/assessments/PD-ASS-197-3-1-1-logging-system.md) | 🔄 Re-testing Needed | 0.1.3 | Structured logging, colored console, JSON file logging, log rotation, runtime filtering |

</details>

<details>
<summary><strong>6. Link Validation & Reporting</strong></summary>

### 6.0 Link Validation & Reporting

On-demand link health auditing and broken link reporting.

|  ID  |  Feature  |  Status  |  Priority  |  Doc Tier  |  Test Status  |  Dependencies  |  Notes  |
|  --  |  -------  |  ------  |  --------  |  --------  |  -----------  |  ------------  |  -----  |
| [6.1.1](<../features/6.1.1-Link Validation-implementation-state.md>) | Link Validation | 🟢 Completed | P2 | [🔵 Tier 1](../../documentation-tiers/assessments/PD-ASS-200-6.1.1-link-validation.md) | ✅ All Passing | 0.1.1, 2.1.1 | On-demand broken link scanning with context-aware filtering; per-folder path-resolution override for designated folders. |

</details>

<details>
<summary><strong>7. Operations & Control</strong></summary>

### 7.1 Control Panel

|  ID  |  Feature  |  Status  |  Priority  |  Doc Tier  |  Test Status  |  Dependencies  |  Notes  |
|  --  |  -------  |  ------  |  --------  |  --------  |  -----------  |  ------------  |  -----  |
| [7.1.1](../features/7.1.1-LinkWatcher-Control-Panel-implementation-state.md) | LinkWatcher Control Panel | 👀 Needs Review | P3 | [🟠 Tier 2](../../documentation-tiers/assessments/PD-ASS-201-7.1.1-linkwatcher-control-panel.md) | ✅ All Passing |  | Desktop window control panel: cross-project daemon management, log viewing, config view/edit, validation triggering, drain-and-terminate on panel close (window auto-opens on hook start).; Assessment completed: PD-ASS-201 (2026-06-29); UI Design: Required — routed to 🎨 Needs UI Design ahead of TDD (UI Design gate added by PF-IMP-1352); FDD created: PD-FDD-034 (2026-06-29); UI Design created: PD-UIX-003 (2026-07-06); TDD created: PD-TDD-033 (2026-07-12); Test specification created: TE-TSP-045 (2026-07-12); Implementation Plan created: PD-IMP-003 (2026-07-15); Core Logic Implementation Phase A complete — settings + registry resolution (pointer discovery) + window-shell foundation, TE-TST-141 13/13 (2026-07-27); Core Logic Implementation Phase B complete — discovery + observable model + live daemon list; panel is now a truthful read-only monitor. TE-TST-142/143/144 (25/22/6) pass, 1030 unit tests green. TDD PD-TDD-033 amended to v1.1 (normalized project-root identity; live-daemon-outranks-stale-lock precedence; frozen-project filtering question resolved) (2026-07-31); Core Logic Implementation Phase C complete — lifecycle actions: start via launcher, observational drain, kill-time-guarded pair termination, self-owned lock cleanup, live toolbar enablement. TE-TST-146 (25) + TE-TST-147 (10, COMP-1) + INT-3/4/9; panel suite 113/113, 1074 unit tests green. Verified live: panel-start + clean drain-stop of TimeTrackingV2's daemon incl. stale-lock reclaim and lock cleanup (2026-08-10); Core Logic Implementation Phase D complete — **PF-TSK-078 done (Phases A–D)**: shutdown orchestration — close drains all managed daemons behind the modal Screen-4 dialog, watchdog-bounded deterministic exit (AC-7/AC-9). INT-5/6 + watchdog/zero-target/adopted-drain + COMP-5; panel suite 123/123, 1087 unit tests green. Verified live: close-with-running-daemon drained TimeTrackingV2 and exited itself in 4.9 s. Next: UI Implementation (PF-TSK-052) Phase E detail panes (2026-08-10); UI Implementation Phase E complete — **PF-TSK-052 done**: all three detail panes live — log tail (incremental, rotation-aware, CRLF-safe, bounded buffer), validation (`--validate` subprocess, report-file count extraction — TDD §8 Q3 resolved, per-project busy guard), config editor (validate-on-save via real `LinkWatcherConfig`, atomic replace, default skeleton), unsaved-changes guard on row+tab switches, Ctrl+1/2/3 / Ctrl+S / Ctrl+End accelerators. TE-TST-148/149/150 created + INT-7 + COMP-3/4/6/7; panel suite 183/183, 1147 unit tests green, TDD v1.2. Verified live: scripted real-Tk run against a synthetic project, 14/14 checks incl. real `--validate` finding a planted broken link (2026-08-10); Integration & Testing Phase F complete — **the panel ships and auto-opens**: `single_instance.py` (loopback bind + `panel.port` + SURFACE/banner handshake + self-owned release), `app.surface()`, hook-wrapper detached `pythonw.exe` auto-open (no redirection → no inherited capture pipe), installer ships `control_panel.py` + panel wrappers + GUI-safe smoke test. TE-TST-151 (23 fns / 29 cases, UNIT-I1…I4); panel suite 212/212, 1180 unit tests green. Verified live: hook wrapper returned in 2.4 s with piped stdout, repeat launch surfaced the same window (AC-11). Step 16 found and fixed three deployment defects — `psutil` and `GitPython` were undeclared runtime deps, and a fresh install aborted at venv creation (installer now generates `requirements.txt`). Next: Phase G hardening (2026-08-10) |

</details>

## Archived Features

<details>
<summary><strong>Show archived features (2 items)</strong></summary>

Features that have been generalized into the process framework or otherwise retired from active product tracking.

| ID | Feature | Archive Date | Rationale | Replacement |
| -- | ------- | ------------ | --------- | ----------- |
| [5.1.1](../features/archive/5.1.1-cicd-development-tooling-implementation-state.md) | CI/CD & Development Tooling | 2026-03-22 | Generalized into framework (PF-PRO-009, 2026-03-22). CI/CD infrastructure is now a framework concern, not a product feature. Major components deleted (ci.yml, run_tests.py, setup_cicd.py). | [CI/CD Setup Guide](../../../process-framework/guides/07-deployment/ci-cd-setup-guide.md) |
| [4.1.1](../features/archive/4.1.1-test-suite-implementation-state.md) | Test Suite | 2026-03-22 | Generalized into framework (PF-PRO-009, 2026-03-22). Testing infrastructure is now a framework concern, not a product feature. | [Test Infrastructure Guide](../../../process-framework/guides/03-testing/test-infrastructure-guide.md) |

</details>

## Progress Summary

<details>
<summary><strong>Implementation Status Overview</strong></summary>

| Status                | Count  | Percentage |
| --------------------- | ------ | ---------- |
| 🟢 Completed | 8      | 88.9%      |
| 👀 Needs Review | 1      | 11.1%      |
| **Total Active**    | **9**  | **100%**   |

> **📝 NOTE**: All 9 active features are fully implemented in code (retrospective). The status reflects documentation completeness, not implementation progress. All features have passing tests. See [Archived Features](#archived-features) for retired features.

</details>

<details>
<summary><strong>Documentation Tier Distribution</strong></summary>

| Tier                  | Count  | Percentage |
| --------------------- | ------ | ---------- |
| 🔵 Tier 1 (Simple)   | 2      | 22.2%      |
| 🟠 Tier 2 (Moderate)   | 6      | 66.7%      |
| 🔴 Tier 3 (Complex)   | 1      | 11.1%      |
| **Total Active**    | **9**  | **100%**   |

</details>

## Tasks That Update This File

<details>
<summary><strong>Tasks That Update This File</strong></summary>

- [Feature Request Evaluation](../../../process-framework/tasks/01-planning/feature-request-evaluation.md): Updates when new features are added and assessed (tier assessment embedded)
- [FDD Creation](../../../process-framework/tasks/02-design/fdd-creation-task.md): Updates when FDDs are created
- [TDD Creation](../../../process-framework/tasks/02-design/tdd-creation-task.md): Updates when technical designs are completed
- [Test Specification Creation](../../../process-framework/tasks/03-testing/test-specification-creation-task.md): Updates Test Status when specs are created; Test Specification link inserted into per-feature state file §4 Documentation Inventory
- [Feature Implementation Planning](../../../process-framework/tasks/04-implementation/feature-implementation-planning-task.md): Creates implementation plan, sets status to "In Progress"
- [Feature Enhancement](../../../process-framework/tasks/04-implementation/feature-enhancement.md): Updates status during enhancement work
- [Code Review](../../../process-framework/tasks/06-maintenance/code-review-task.md): Updates when reviews are completed
- [Performance & E2E Test Scoping](../../../process-framework/tasks/03-testing/performance-e2e-test-scoping-task.md): Updates status from `🔎 Needs Test Scoping` to `🟢 Completed` after test needs identification

</details>

## Update History

| Date | Change | Updated By |
|------|--------|------------|
| 2026-06-04 | v2.19 — Schema migrated to lightweight cross-feature index per PF-PRO-002 / PF-IMP-760 (MIG-001, Framework Rollout Mode C): dropped FDD / TDD / Test Spec columns from all 5 category tables; reworded status legend to remove "column = Yes" gate language (now references the assessment Design Requirements Evaluation section + per-feature state file §4 Documentation Inventory); dropped Documentation Coverage static-counter section (cross-feature query now via Get-FeatureDesignArtifacts.ps1); backfilled Test Spec links into 0.1.3 (TE-TSP-037) and 1.1.1 (TE-TSP-044) state files. | [Framework Rollout Mode C (PF-TSK-088)](../../../process-framework/tasks/support/framework-rollout-task.md) |
| 2026-04-12 | v2.18 — 6.1.1 Link Validation: Test scoping complete (no new performance tests needed — BM-005 already covers validation mode at L2; WF-009 "Link health audit" added to user-workflow-tracking.md and e2e-test-tracking.md milestone), status → 🟢 Completed | [Performance & E2E Test Scoping (PF-TSK-086)](../../../process-framework/tasks/03-testing/performance-and-e2e-test-scoping-task.md) |
| 2026-04-12 | v2.17 — 3.1.1 Logging System: Test scoping complete (no performance tests needed — logging is not hot-path per scoping guide; no new E2E milestones — all 3 workflows WF-003/006/007 already have milestone entries), status → 🟢 Completed | [Performance & E2E Test Scoping (PF-TSK-086)](../../../process-framework/tasks/03-testing/performance-and-e2e-test-scoping-task.md) |
| 2026-04-12 | v2.16 — 2.1.1 Link Parsing System: Test scoping complete (no new performance tests needed — BM-001/BM-003/BM-005/PH-003 already cover parser system at L1/L2/L3; no new E2E tests — all 4 workflows WF-001/002/003/005 already have milestones and test cases), status → 🟢 Completed | [Performance & E2E Test Scoping (PF-TSK-086)](../../../process-framework/tasks/03-testing/performance-and-e2e-test-scoping-task.md) |
| 2026-04-12 | v2.15 — 0.1.3 Configuration System: Test scoping complete (no performance tests needed — config is not hot-path; WF-006 milestone added to e2e-test-tracking.md), status → 🟢 Completed | [Performance & E2E Test Scoping (PF-TSK-086)](../../../process-framework/tasks/03-testing/performance-and-e2e-test-scoping-task.md) |
| 2026-04-12 | v2.14 — 0.1.1 Core Architecture: Test scoping complete (no new performance/E2E tests needed — existing coverage adequate), status → 🟢 Completed | [Performance & E2E Test Scoping (PF-TSK-086)](../../../process-framework/tasks/03-testing/performance-and-e2e-test-scoping-task.md) |
| 2026-04-11 | v2.13 — **Next-Action Status Model**: Replaced last-completed statuses with next-action statuses (PF-PRO-018/PF-STA-083). Legend restructured, 0.1.1 → Completed, 6.1.1 → Needs Enhancement. Parallel design tasks (ADR/API/DB) gated by scripts, not primary status chain. | [Structure Change (PF-TSK-014)](../../../process-framework/tasks/support/structure-change-task.md) |
| 2026-03-27 | v2.12 — 6.1.1 Link Validation: User documentation created (PD-UGD-003 link-validation handbook, quick-reference updated, README updated). | [User Documentation Creation (PF-TSK-081)](../../../process-framework/tasks/07-deployment/user-documentation-creation.md) |
| 2026-03-26 | v2.11 — 0.1.3 Configuration System set to "Needs Revision" for Ignored Patterns Configuration enhancement (PF-STA-066) | [Feature Request Evaluation (PF-TSK-067)](../../../process-framework/tasks/01-planning/feature-request-evaluation.md) |
| 2026-03-24 | v2.10 — 6.1.1 Link Validation: Code review complete. Filtering improvements (93% false positive reduction, 46 tests). Status → 🔄 Needs Revision (PD-BUG-051 remaining false positives). | [Code Review (PF-TSK-005)](../../../process-framework/tasks/06-maintenance/code-review-task.md) |
| 2026-03-24 | v2.9 — 6.1.1 Link Validation: All 3 implementation phases complete (validator.py, CLI --validate, 20 unit tests), status → ⚙️ Implementation | Implementation |
| 2026-03-24 | v2.8 — 6.1.1 Link Validation: Implementation plan created (PD-IMP-002), status → 📋 Implementation Planned | [Feature Implementation Planning (PF-TSK-044)](../../../process-framework/tasks/04-implementation/feature-implementation-planning-task.md) |
| 2026-03-16 | v2.7 — 1.1.1 File System Monitoring set to "Needs Revision" for Parent Directory Reference Updates enhancement (PF-STA-058) | [Feature Request Evaluation (PF-TSK-067)](../../../process-framework/tasks/01-planning/feature-request-evaluation.md) |
| 2026-03-16 | v2.6 — 2.1.1 Link Parsing System set to "Needs Revision" for Backtick-Delimited Path Detection enhancement (PF-STA-057) | [Feature Request Evaluation (PF-TSK-067)](../../../process-framework/tasks/01-planning/feature-request-evaluation.md) |
| 2026-03-16 | v2.5 — Added feature 6.1.1 Link Validation in new category "6. Link Validation & Reporting" (PF-FEA-055) | [Feature Request Evaluation (PF-TSK-067)](../../../process-framework/tasks/01-planning/feature-request-evaluation.md) |
| 2026-02-25 | v2.4 — 0.1.1 Core Architecture: Duplicate Session Prevention enhancement complete, status → 🟢 Completed | [Feature Enhancement (PF-TSK-068)](../../../process-framework/tasks/04-implementation/feature-enhancement.md) |
| 2026-02-25 | v2.3 — 0.1.1 Core Architecture set to "Needs Revision" for Duplicate Session Prevention enhancement (PF-STA-049) | [Feature Request Evaluation (PF-TSK-067)](../../../process-framework/tasks/01-planning/feature-request-evaluation.md) |
| 2026-02-24 | v2.2 — All 9 test specifications created (PF-TSP-035 through PF-TSP-043), Test Spec column fully populated | [Test Specification Creation (PF-TSK-012)](../../../process-framework/tasks/03-testing/test-specification-creation-task.md) |
| 2026-02-21 | v2.1 — Created 9 consolidated feature state files (PF-FEA-046 to PF-FEA-054), linked all IDs and assessments | [Structure Change (PF-TSK-009)](../../../process-framework/tasks/support/structure-change-task.md) |
| 2026-02-20 | v2.0 — Consolidated 42 features → 9 features | [Structure Change (PF-TSK-009)](../../../process-framework/tasks/support/structure-change-task.md) |
| 2026-02-20 | v1.5 — Retrospective TDDs completed for all Tier 2+ features | [Retrospective Documentation Creation (PF-TSK-066)](../../../process-framework/tasks/00-setup/retrospective-documentation-creation.md) |
| 2026-02-19 | v1.4 — Retrospective FDDs completed for all Tier 2+ features | [Retrospective Documentation Creation (PF-TSK-066)](../../../process-framework/tasks/00-setup/retrospective-documentation-creation.md) |
| 2026-02-17 | v1.0 — Initial feature tracking with 42 features | [Codebase Feature Discovery (PF-TSK-064)](../../../process-framework/tasks/00-setup/codebase-feature-discovery.md) |
| 2026-03-22 | Archived feature 4.1.1: Generalized into framework (PF-PRO-009, 2026-03-22). Testing infrastructure is now a framework concern, not a product feature. | [Archive-Feature.ps1](../../../process-framework/scripts/update/Archive-Feature.ps1) |
| 2026-03-22 | Archived feature 5.1.1: Generalized into framework (PF-PRO-009, 2026-03-22). CI/CD infrastructure is now a framework concern, not a product feature. Major components deleted (ci.yml, run_tests.py, setup_cicd.py). | [Archive-Feature.ps1](../../../process-framework/scripts/update/Archive-Feature.ps1) |
| 2026-07-06 | Feature 2.2.1: 🔄 Needs Enhancement → 👀 Needs Review (enhancement finalized) | [Finalize-Enhancement.ps1](../../../process-framework/scripts/update/Finalize-Enhancement.ps1) |
| 2026-07-06 | Feature 2.2.1: 👀 Needs Review → 🔄 Needs Enhancement — Code Review of the blueprint-aware reference updating change set: 1 Major finding (residual virtual-root hijack via PD-BUG-045 suffix block; OPEN implementation gap in state file §9), all other dimensions PASS (968 tests green; acceptance criteria FR-8/FR-9/BR-9/AC-7 met, BR-8 unmet at the gap edge). Fix + re-review before release. Reviewer: AI Agent + Human Partner. | [Code Review (PF-TSK-005)](../../../process-framework/tasks/06-maintenance/code-review-task.md) |
| 2026-07-12 | Feature 2.2.1: 🔄 Needs Enhancement → 👀 Needs Review — implementation gap fixed (bug-fix-style follow-up): PD-BUG-045 suffix block gated on `not is_virtual_root_link` in path_resolver; regression test added (failed pre-fix with exact hijack signature, passes post-fix); PD-TDD-026 overclaiming wording corrected; TE-TSP-040 scenario (f) added. Full suite 963 passed / 0 failed. State file §9 gap closed. Ready for Code Review repeat cycle. | [Bug Fixing (PF-TSK-007)](../../../process-framework/tasks/06-maintenance/bug-fixing-task.md) |
| 2026-07-12 | Feature 2.2.1: 👀 Needs Review → 🔎 Needs Test Scoping — Code Review repeat cycle PASSED (gap-fix delta): suffix-block gate verified correct and class-closing (all three unresolved-form comparison sites now share one gating condition; Step-3 matchers confirmed resolved-form only; Python-import sibling confirmed not exposed); regression test faithfully reproduces the hijack; TDD/test-spec corrections accurate. Scoped tests 60/60, full suite 955 passed / 0 failed, black clean. Findings: 0 Critical/Major/Minor; 1 Suggestion (path_resolver module docstring lags v1.1 flow — routed to Code Refactoring lightweight path). Status set via `Update-FeatureTrackingStatus` helper: `Update-CodeReviewState.ps1 -ReviewStatus "Completed"` maps to non-legend "✅ Review Completed" (script drift filed as IMP). Reviewer: AI Agent + Human Partner. | [Code Review (PF-TSK-005)](../../../process-framework/tasks/06-maintenance/code-review-task.md) |
