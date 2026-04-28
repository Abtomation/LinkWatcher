---
id: PD-MAI-001
type: Product Documentation
category: Documentation Map
version: 1.0
created: 2026-04-03
updated: 2026-04-03
---

# Product Documentation Map

This document indexes all product documentation in the `doc` directory — what we're building, how it's designed, and its current state.

> **See also**: [Process Framework Documentation Map](/process-framework/PF-documentation-map.md) | [Test Documentation Map](/test/TE-documentation-map.md)

## `documentation-tiers/` — Feature Tier Assessments

- [Tier Assessments README](documentation-tiers/README.md) - Overview of the documentation tier system

### `documentation-tiers/assessments/`

- [Assessment: Core Architecture 0.1.1 (PD-ASS-191)](documentation-tiers/assessments/PD-ASS-191-0-1-1-core-architecture.md)
- [Assessment: In-Memory Link Database 0.1.2 (PD-ASS-192)](documentation-tiers/assessments/PD-ASS-192-0-1-2-in-memory-link-database.md)
- [Assessment: Configuration System 0.1.3 (PD-ASS-193)](documentation-tiers/assessments/PD-ASS-193-0-1-3-configuration-system.md)
- [Assessment: File System Monitoring 1.1.1 (PD-ASS-194)](documentation-tiers/assessments/PD-ASS-194-1-1-1-file-system-monitoring.md)
- [Assessment: Link Parsing System 2.1.1 (PD-ASS-195)](documentation-tiers/assessments/PD-ASS-195-2-1-1-link-parsing-system.md)
- [Assessment: Link Updating 2.2.1 (PD-ASS-196)](documentation-tiers/assessments/PD-ASS-196-2-2-1-link-updating.md)
- [Assessment: Logging System 3.1.1 (PD-ASS-197)](documentation-tiers/assessments/PD-ASS-197-3-1-1-logging-system.md)
- [Assessment: Test Suite 4.1.1 (PD-ASS-198)](documentation-tiers/assessments/PD-ASS-198-4-1-1-test-suite.md)
- [Assessment: CI/CD & Development Tooling 5.1.1 (PD-ASS-199)](documentation-tiers/assessments/PD-ASS-199-5-1-1-ci-cd-development-tooling.md)
- [Assessment: Link Validation 6.1.1 (PD-ASS-200)](documentation-tiers/assessments/PD-ASS-200-6.1.1-link-validation.md)

## `functional-design/` — Functional Design Documents (FDDs)

_Created during framework onboarding (PF-TSK-066), consolidated to 9-feature scope (2026-02-20)._

### `functional-design/fdds/`

- [FDD: Core Architecture (PD-FDD-022)](functional-design/fdds/fdd-0-1-1-core-architecture.md) - 0.1.1 Tier 3 — Orchestrator/Facade service, data models, path utilities
- [FDD: In-Memory Link Database (PD-FDD-023)](functional-design/fdds/fdd-0-1-2-in-memory-database.md) - 0.1.2 Tier 2 — Thread-safe link storage with O(1) lookups
- [FDD: File System Monitoring (PD-FDD-024)](functional-design/fdds/fdd-1-1-1-file-system-monitoring.md) - 1.1.1 Tier 2 — Watchdog event handling, move detection, file filtering
- [FDD: Link Parsing System (PD-FDD-026)](functional-design/fdds/fdd-2-1-1-parser-framework.md) - 2.1.1 Tier 2 — Parser registry/facade with 6 format-specific parsers
- [FDD: Link Updating (PD-FDD-027)](functional-design/fdds/fdd-2-2-1-link-updater.md) - 2.2.1 Tier 2 — Atomic file updates, relative path calculation, dry-run
- [FDD: Logging System (PD-FDD-025)](functional-design/fdds/fdd-3-1-1-logging-framework.md) - 3.1.1 Tier 2 — Structured logging with colored output, stats, progress
- ~~FDD: Test Suite (PD-FDD-028)~~ - 🗄️ Archived (PF-PRO-009) — generalized into [Test Infrastructure Guide](/process-framework/guides/03-testing/test-infrastructure-guide.md)
- ~~FDD: CI/CD & Development Tooling (PD-FDD-032)~~ - 🗄️ Archived (PF-PRO-009) — generalized into [CI/CD Setup Guide](/process-framework/guides/07-deployment/ci-cd-setup-guide.md)

> **Note**: 0.1.3 Configuration System is Tier 1 — no FDD required.

## `refactoring/` — Refactoring Plans

### `refactoring/plans/`

- [Refactoring: Remove Incorrect Colorama Dependency](refactoring/plans/remove-incorrect-colorama-dependency-from-updater-tdd-and-fdd.md)

## `state-tracking/` — Product State Tracking

### `state-tracking/features/` — Feature Implementation State Files

- [Feature State: Core Architecture 0.1.1](state-tracking/features/0.1.1-core-architecture-implementation-state.md)
- [Feature State: In-Memory Link Database 0.1.2](state-tracking/features/0.1.2-in-memory-link-database-implementation-state.md)
- [Feature State: Configuration System 0.1.3](state-tracking/features/0.1.3-configuration-system-implementation-state.md)
- [Feature State: File System Monitoring 1.1.1](state-tracking/features/1.1.1-file-system-monitoring-implementation-state.md)
- [Feature State: Link Parsing System 2.1.1](state-tracking/features/2.1.1-link-parsing-system-implementation-state.md)
- [Feature State: Link Updating 2.2.1](state-tracking/features/2.2.1-link-updating-implementation-state.md)
- [Feature State: Logging System 3.1.1](state-tracking/features/3.1.1-logging-system-implementation-state.md)
- [Feature State: Link Validation 6.1.1](state-tracking/features/6.1.1-Link%20Validation-implementation-state.md)

### `state-tracking/permanent` — Permanent State Files

- [State: Feature Tracking](state-tracking/permanent/feature-tracking.md) - Comprehensive list of all features with implementation status
- [State: Feature Request Tracking](state-tracking/permanent/feature-request-tracking.md) - Intake queue for product feature requests before classification by Feature Request Evaluation
- [State: Technical Debt Tracking](state-tracking/permanent/technical-debt-tracking.md) - System for tracking and managing technical debt
- [State: Bug Tracking](state-tracking/permanent/bug-tracking.md) - Bug reports and fix status
- [State: Architecture Tracking](state-tracking/permanent/architecture-tracking.md) - Cross-cutting architectural state management and AI agent continuity
- [State: User Workflow Tracking](state-tracking/permanent/user-workflow-tracking.md) - Maps user-facing workflows to required features; bridge between feature-centric development and cross-feature E2E testing

### `state-tracking/temporary/` — Temporary State Files

- [State: Validation Tracking — Round 4](state-tracking/validation/validation-tracking-4.md) - Round 4 post-bug-fix re-validation tracking (10 dimensions × 8 features, 65 validations)
- [State: Validation Tracking — Round 3](state-tracking/validation/archive/validation-tracking-3.md) - Round 3 post-enhancement re-validation tracking (10 dimensions × 8 features, workflow cohort grouping)
- [State: Validation Tracking — Round 2](state-tracking/validation/archive/validation-tracking-2.md) - Round 2 comprehensive re-validation tracking (10 dimensions × 8 features)
- [State: Validation Tracking — Round 1](state-tracking/validation/archive/validation-tracking-1.md) - Round 1 foundational validation tracking (completed 2026-03-16, 6 dimensions × 9 features)

## `technical/` — Technical Design

### `technical/adr/` — Architecture Decision Records (ADRs)

_Created during framework onboarding (PF-TSK-066) — documenting existing architectural decisions._

- [ADR: Orchestrator/Facade Pattern (PD-ADR-039)](technical/adr/orchestrator-facade-pattern-for-core-architecture.md) - 0.1.1 Core Architecture pattern decision
- [ADR: Target-Indexed In-Memory Link Database (PD-ADR-040)](technical/adr/target-indexed-in-memory-link-database.md) - 0.1.2 In-Memory Link Database storage strategy
- [ADR: Timer-Based Move Detection with 3-Phase Directory Batch Algorithm (PD-ADR-041)](technical/adr/timer-based-move-detection-with-3-phase-directory-batch-algorithm.md) - 1.1.1 File System Monitoring delete+create correlation and dual-timer strategy

### `technical/implementation-plans/`

- [Implementation Plan: Link Validation 6.1.1](technical/implementation-plans/6-1-1-link-validation-implementation-plan.md)

### `technical/tdd/` — Technical Design Documents (TDDs)

_Created during framework onboarding (PF-TSK-066), consolidated to 9-feature scope (2026-02-20)._

- [TDD: Core Architecture (PD-TDD-021)](technical/tdd/tdd-0-1-1-core-architecture-t3.md) - 0.1.1 Tier 3 — Full architecture with component diagrams
- [TDD: In-Memory Link Database (PD-TDD-022)](technical/tdd/tdd-0-1-2-in-memory-database-t2.md) - 0.1.2 Tier 2 — Target-indexed storage design
- [TDD: File System Monitoring (PD-TDD-023)](technical/tdd/tdd-1-1-1-file-system-monitoring-t2.md) - 1.1.1 Tier 2 — State machine, timer-based move detection
- [TDD: Link Parsing System (PD-TDD-025)](technical/tdd/tdd-2-1-1-parser-framework-t2.md) - 2.1.1 Tier 2 — Registry + Facade parser system
- [TDD: Link Updating (PD-TDD-026)](technical/tdd/tdd-2-2-1-link-updater-t2.md) - 2.2.1 Tier 2 — Bottom-to-top atomic write strategy
- [TDD: Logging System (PD-TDD-024)](technical/tdd/tdd-3-1-1-logging-framework-t2.md) - 3.1.1 Tier 2 — Dual-formatter logging design
- ~~TDD: Test Suite (PD-TDD-027)~~ - 🗄️ Archived (PF-PRO-009) — generalized into [Test Infrastructure Guide](/process-framework/guides/03-testing/test-infrastructure-guide.md)
- ~~TDD: CI/CD & Development Tooling (PD-TDD-031)~~ - 🗄️ Archived (PF-PRO-009) — generalized into [CI/CD Setup Guide](/process-framework/guides/07-deployment/ci-cd-setup-guide.md)

> **Note**: 0.1.3 Configuration System is Tier 1 — no TDD required.

### `technical/` — Other

- [Product: Feature Dependencies](technical/architecture/feature-dependencies.md) - Auto-generated visual map and matrix of feature dependencies

### `technical/integration/` — Integration Narratives

_Created via Integration Narrative Creation task (PF-TSK-083) — documenting cross-feature workflow collaboration._

- [Product: Startup (PD-INT-001)](technical/integration/startup-integration-narrative.md) - WF-003 startup and initial project scan: how Core Architecture, Configuration, Logging, Database, Parser, and File System Monitoring collaborate from `python main.py` to active monitoring
- [Product: Single File Move (PD-INT-002)](technical/integration/single-file-move-integration-narrative.md) - WF-001 single-file move pipeline: how File System Monitoring, In-Memory Database, Parser Framework, and Link Updater collaborate from watchdog event detection to atomic reference rewrites and DB re-sync
- [Product: Dry-Run Mode (PD-INT-003)](technical/integration/dry-run-mode-integration-narrative.md) - WF-007 dry-run preview mode: how Configuration System, Core Architecture, Link Updater, and Logging Framework collaborate to short-circuit disk writes and report intended changes as structured log events
- [Product: Multi-Format File Move (PD-INT-004)](technical/integration/multi-format-file-move-integration-narrative.md) - WF-005 multi-format file move: how File System Monitoring, Parser Framework, and Link Updater collaborate so a single move correctly rewrites references across MD, YAML, JSON, Python, PS1, and generic-fallback formats via `link_type`-tagged `LinkReference` dispatch
- [Product: Link Health Audit (PD-INT-005)](technical/integration/link-health-audit-integration-narrative.md) - WF-009 validation mode: how Core Architecture, Configuration System, Parser Framework, and Link Validation collaborate when `python main.py --validate` performs a read-only workspace scan and writes `LinkWatcherBrokenLinks.txt` — standalone from the live-watching pipeline (no lock, no observer, no service, no database)
- [Product: Directory Move (PD-INT-006)](technical/integration/directory-move-integration-narrative.md) - WF-002 directory move pipeline: how File System Monitoring (DirectoryMoveDetector 3-phase state machine with settle+max timers + native `DirMovedEvent`), In-Memory Database, Parser Framework, and Link Updater collaborate through the 5-phase batched pipeline (Phase 0 source-path re-key, Phase 1/1b/1c batched collect→single-pass update (TD129)→deferred bulk rescan (TD128), Phase 1.5 inside-file relative links, Phase 2 directory-path refs) to update every inbound reference, every contained file's outward links, and every reference to the directory path itself in a single orchestrated flow
- [Product: Rapid Sequential Moves (PD-INT-007)](technical/integration/rapid-sequential-moves-integration-narrative.md) - WF-004 rapid sequential moves: how File System Monitoring, In-Memory Database, and Link Updater preserve consistency when multiple file moves arrive in tight succession — observer-thread serialization, MoveDetector pending-map concurrency, DB lock contention, and the stale-reference retry cascade
- [Product: Graceful Shutdown (PD-INT-008)](technical/integration/graceful-shutdown-integration-narrative.md) - WF-008 graceful shutdown: how Core Architecture (signal handlers, observer lifecycle, lock file), Link Updater (atomic temp-file + rename writes), and In-Memory Database (discard-on-exit; no persistence) collaborate so Ctrl+C / SIGTERM never leaves files partially written — from signal delivery through observer drain to lock release
- [Product: Configuration Change (PD-INT-009)](technical/integration/configuration-change-integration-narrative.md) - WF-006 configuration change: how Configuration System, Core Architecture, File System Monitoring, Parser Framework, Link Updater, and Logging Framework collaborate at startup so values from YAML/JSON files, `LINKWATCHER_*` env vars, and CLI flags cascade into per-component constructor arguments, post-`__init__` setters, and the logging singleton — one-shot propagation with no hot-reload

## `user/` — User Documentation

### `user/handbooks/`

- [Product: Quick Reference (PD-UGD-007)](user/handbooks/quick-reference.md) - CLI options, config, environment variables, examples
- [Product: Multi-Project Setup (PD-UGD-008)](user/handbooks/multi-project-setup.md) - Using across multiple projects
- [Product: Link Validation (PD-UGD-003)](user/handbooks/link-validation.md) - On-demand workspace scan for broken file references using --validate
- [Product: File Type Quick Fix (PD-UGD-001)](user/handbooks/file-type-quick-fix.md) - Quick solutions for adding file type monitoring support
- [Product: Troubleshooting File Types (PD-UGD-002)](user/handbooks/troubleshooting-file-types.md) - Detailed diagnosis and fixes for file type monitoring issues
- [Product: LinkWatcher Capabilities Reference (PD-UGD-004)](user/handbooks/linkwatcher-capabilities-reference.md) - Complete reference of all detection patterns, parsers, and update triggers
- [Product: Configuration Guide (PD-UGD-005)](user/handbooks/configuration-guide.md) - Complete guide to configuring LinkWatcher: config files, CLI arguments, environment variables, presets, and the ignore system
- [Product: Logging and Monitoring (PD-UGD-006)](user/handbooks/logging-and-monitoring.md) - Guide to configuring logging output, file logging, log rotation, and the real-time monitoring dashboard

## `validation/` — Validation Reports

_Created during feature validation (PF-TSK-031 through PF-TSK-036)._

### Round 1 Validation Reports

- [Validation: Architectural Consistency — Features 0.1.1–1.1.1 (PD-VAL-035)](validation/reports/architectural-consistency/PD-VAL-035-architectural-consistency-features-0.1.1-1.1.1.md) - Batch 1 (Score: 3.475/4.0 PASS)
- [Validation: Architectural Consistency — Features 2.1.1–5.1.1 (PD-VAL-036)](validation/reports/architectural-consistency/PD-VAL-036-architectural-consistency-features-2.1.1-2.2.1-3.1.1-4.1.1-5.1.1.md) - Batch 2 (Score: 3.450/4.0 PASS)
- [Validation: Code Quality — Features 0.1.1–1.1.1 (PD-VAL-037)](validation/reports/code-quality/PD-VAL-037-code-quality-features-0.1.1-0.1.2-0.1.3-1.1.1.md) - Batch 1 (Score: 3.050/4.0 PASS)
- [Validation: Code Quality — Features 2.1.1–5.1.1 (PD-VAL-038)](validation/reports/code-quality/PD-VAL-038-code-quality-features-2.1.1-2.2.1-3.1.1-4.1.1-5.1.1.md) - Batch 2 (Score: 3.120/4.0 PASS)
- [Validation: Integration Dependencies — Features 0.1.1–1.1.1 (PD-VAL-039)](validation/reports/integration-dependencies/PD-VAL-039-integration-dependencies-features-0.1.1-0.1.2-0.1.3-1.1.1.md) - Batch 1 (Score: 3.200/4.0 PASS)
- [Validation: Integration Dependencies — Features 2.1.1–5.1.1 (PD-VAL-041)](validation/reports/integration-dependencies/PD-VAL-041-integration-dependencies-features-2.1.1-2.2.1-3.1.1-4.1.1-5.1.1.md) - Batch 2 (Score: 3.400/4.0 PASS)
- [Validation: Documentation Alignment — Features 0.1.1–1.1.1 (PD-VAL-042)](validation/reports/documentation-alignment/PD-VAL-042-documentation-alignment-features-0.1.1-0.1.2-0.1.3-1.1.1.md) - Batch 1 (Score: 2.55/4.0 PASS)
- [Validation: Documentation Alignment — Features 2.1.1–5.1.1 (PD-VAL-043)](validation/reports/documentation-alignment/PD-VAL-043-documentation-alignment-features-2.1.1-2.2.1-3.1.1-4.1.1-5.1.1.md) - Batch 2 (Score: 2.24/4.0 PASS)
- [Validation: Extensibility & Maintainability — All Features (PD-VAL-044)](validation/reports/extensibility-maintainability/PD-VAL-044-extensibility-maintainability-features-0.1.1-0.1.2-0.1.3-1.1.1-2.1.1-2.2.1-3.1.1-4.1.1-5.1.1.md) - All 9 features (Score: 3.044/4.0 PASS)
- [Validation: AI Agent Continuity — All Features (PD-VAL-045)](validation/reports/ai-agent-continuity/PD-VAL-045-ai-agent-continuity-features-0.1.1-0.1.2-0.1.3-1.1.1-2.1.1-2.2.1-3.1.1-4.1.1-5.1.1.md) - All 9 features (Score: 3.244/4.0 PASS)

### Round 2 Validation Reports

- [Validation: Architectural Consistency — Features 0.1.1–1.1.1 R2 (PD-VAL-046)](validation/reports/architectural-consistency/PD-VAL-046-architectural-consistency-features-0.1.1-0.1.2-0.1.3-1.1.1.md) - Batch A (Score: 2.8/3.0 PASS)
- [Validation: Architectural Consistency — Features 2.1.1–6.1.1 R2 (PD-VAL-047)](validation/reports/architectural-consistency/PD-VAL-047-architectural-consistency-features-2.1.1-2.2.1-3.1.1-6.1.1.md) - Batch B (Score: 2.8/3.0 PASS)
- [Validation: Code Quality — Features 0.1.1–1.1.1 R2 (PD-VAL-048)](validation/reports/code-quality/PD-VAL-048-code-quality-features-0.1.1-0.1.2-0.1.3-1.1.1.md) - Batch A (Score: 2.65/3.0 PASS)
- [Validation: Code Quality — Features 2.1.1–6.1.1 R2 (PD-VAL-060)](validation/reports/code-quality/PD-VAL-060-code-quality-features-2.1.1-2.2.1-3.1.1-6.1.1.md) - Batch B (Score: 2.40/3.0 PASS)
- [Validation: Integration Dependencies — Features 0.1.1–1.1.1 R2 (PD-VAL-049)](validation/reports/integration-dependencies/PD-VAL-049-integration-dependencies-features-0.1.1-0.1.2-0.1.3-1.1.1.md) - Batch A (Score: 2.65/3.0 PASS)
- [Validation: Integration Dependencies — Features 2.1.1–6.1.1 R2 (PD-VAL-058)](validation/reports/integration-dependencies/PD-VAL-058-integration-dependencies-features-2.1.1-2.2.1-3.1.1-6.1.1.md) - Batch B (Score: 2.65/3.0 PASS)
- [Validation: Extensibility & Maintainability — Features 0.1.1–1.1.1 R2 (PD-VAL-050)](validation/reports/extensibility-maintainability/PD-VAL-050-extensibility-maintainability-features-0.1.1-0.1.2-0.1.3-1.1.1.md) - Batch A (Score: 2.7/3.0 PASS)
- [Validation: Extensibility & Maintainability — Features 2.1.1–6.1.1 R2 (PD-VAL-057)](validation/reports/extensibility-maintainability/PD-VAL-057-extensibility-maintainability-features-2.1.1-2.2.1-3.1.1-6.1.1.md) - Batch B (Score: 2.5/3.0 PASS)
- [Validation: AI Agent Continuity — Features 0.1.1–1.1.1 R2 (PD-VAL-052)](validation/reports/ai-agent-continuity/PD-VAL-052-ai-agent-continuity-features-0.1.1-0.1.2-0.1.3-1.1.1.md) - Batch A (Score: 2.55/3.0 PASS)
- [Validation: AI Agent Continuity — Features 2.1.1–6.1.1 R2 (PD-VAL-061)](validation/reports/ai-agent-continuity/PD-VAL-061-ai-agent-continuity-features-2.1.1-2.2.1-3.1.1-6.1.1.md) - Batch B (Score: 2.45/3.0 PASS)
- [Validation: Documentation Alignment — Features 0.1.1–1.1.1 R2 (PD-VAL-051)](validation/reports/documentation-alignment/PD-VAL-051-documentation-alignment-features-0.1.1-0.1.2-0.1.3-1.1.1.md) - Session 7 (Score: 2.6/3.0 PASS)
- [Validation: Documentation Alignment — Features 2.1.1–6.1.1 R2 (PD-VAL-062)](validation/reports/documentation-alignment/PD-VAL-062-documentation-alignment-features-2.1.1-2.2.1-3.1.1-6.1.1.md) - Session 8 (Score: 2.66/3.0 PASS)
- [Validation: Security & Data Protection — Features 0.1.3–6.1.1 R2 (PD-VAL-056)](validation/reports/security-data-protection/PD-VAL-056-security-data-protection-features-0.1.3-1.1.1-2.2.1-6.1.1.md) - Session 13 (Score: 2.9/3.0 PASS)
- [Validation: Performance & Scalability — Features 0.1.1–1.1.1 R2 (PD-VAL-055)](validation/reports/performance-scalability/PD-VAL-055-performance-scalability-features-0.1.1-0.1.2-1.1.1.md) - Session 14 (Score: 2.5/3.0 PASS)
- [Validation: Performance & Scalability — Features 2.1.1–6.1.1 R2 (PD-VAL-059)](validation/reports/performance-scalability/PD-VAL-059-performance-scalability-features-2.1.1-2.2.1-6.1.1.md) - Session 15 (Score: 2.3/3.0 PASS)
- [Validation: Observability — Features 0.1.1–6.1.1 R2 (PD-VAL-054)](validation/reports/observability/PD-VAL-054-observability-features-0.1.1-1.1.1-3.1.1-6.1.1.md) - Session 16 (Score: 2.31/3.0 PASS)
- [Validation: Data Integrity — Features 0.1.2–6.1.1 R2 (PD-VAL-053)](validation/reports/data-integrity/PD-VAL-053-data-integrity-features-0.1.2-2.2.1-6.1.1.md) - Session 17 (Score: 2.44/3.0 PASS)

### Round 3 Validation Reports

- [Validation: Architectural Consistency — Features 0.1.1–1.1.1 R3 (PD-VAL-064)](validation/reports/architectural-consistency/PD-VAL-064-architectural-consistency-features-0.1.1-0.1.2-0.1.3-1.1.1.md) - Session 1 (Score: 2.9/3.0 PASS)
- [Validation: Architectural Consistency — Features 2.1.1–6.1.1 R3 (PD-VAL-073)](validation/reports/architectural-consistency/PD-VAL-073-architectural-consistency-features-2.1.1-2.2.1-3.1.1-6.1.1.md) - Session 2 (Score: 2.85/3.0 PASS)
- [Validation: Code Quality — Features 0.1.1–1.1.1 R3 (PD-VAL-070)](validation/reports/code-quality/PD-VAL-070-code-quality-features-0.1.1-0.1.2-0.1.3-1.1.1.md) - Session 3 (Score: 2.775/3.0 PASS)
- [Validation: Code Quality — Features 2.1.1–6.1.1 R3 (PD-VAL-065)](validation/reports/code-quality/PD-VAL-065-code-quality-features-2.1.1-2.2.1-3.1.1-6.1.1.md) - Session 4 (Score: 2.50/3.0 PASS)
- [Validation: Integration Dependencies — Features 0.1.1–1.1.1 R3 (PD-VAL-067)](validation/reports/integration-dependencies/PD-VAL-067-integration-dependencies-features-0.1.1-0.1.2-0.1.3-1.1.1.md) - Session 5 (Score: 2.85/3.0 PASS)
- [Validation: Integration Dependencies — Features 2.1.1–6.1.1 R3 (PD-VAL-066)](validation/reports/integration-dependencies/PD-VAL-066-integration-dependencies-features-2.1.1-2.2.1-3.1.1-6.1.1.md) - Session 6 (Score: 2.80/3.0 PASS)
- [Validation: Documentation Alignment — Features 0.1.1–1.1.1 R3 (PD-VAL-072)](validation/reports/documentation-alignment/PD-VAL-072-documentation-alignment-features-0.1.1-0.1.2-0.1.3-1.1.1.md) - Session 7 (Score: 2.35/3.0 PASS)
- [Validation: Documentation Alignment — Features 2.1.1–6.1.1 R3 (PD-VAL-071)](validation/reports/documentation-alignment/PD-VAL-071-documentation-alignment-features-2.1.1-2.2.1-3.1.1-6.1.1.md) - Session 8 (Score: 2.38/3.0 PASS)
- [Validation: Extensibility & Maintainability — Features 0.1.1–1.1.1 R3 (PD-VAL-069)](validation/reports/extensibility-maintainability/PD-VAL-069-extensibility-maintainability-features-0.1.1-0.1.2-0.1.3-1.1.1.md) - Session 9 (Score: 2.9/3.0 PASS)
- [Validation: Extensibility & Maintainability — Features 2.1.1–6.1.1 R3 (PD-VAL-068)](validation/reports/extensibility-maintainability/PD-VAL-068-extensibility-maintainability-features-2.1.1-2.2.1-3.1.1-6.1.1.md) - Session 10 (Score: 2.6/3.0 PASS)
- [Validation: AI Agent Continuity — Features 0.1.1–1.1.1 R3 (PD-VAL-074)](validation/reports/ai-agent-continuity/PD-VAL-074-ai-agent-continuity-features-0.1.1-0.1.2-0.1.3-1.1.1.md) - Session 11 (Score: 2.65/3.0 PASS)
- [Validation: AI Agent Continuity — Features 2.1.1–6.1.1 R3 (PD-VAL-075)](validation/reports/ai-agent-continuity/PD-VAL-075-ai-agent-continuity-features-2.1.1-2.2.1-3.1.1-6.1.1.md) - Session 12 (Score: 2.30/3.0 PASS)
- [Validation: Security & Data Protection — Features 0.1.3–6.1.1 R3 (PD-VAL-077)](validation/reports/security-data-protection/PD-VAL-077-security-data-protection-features-0.1.3-1.1.1-2.2.1-6.1.1.md) - Session 13 (Score: 3.0/3.0 PASS)
- [Validation: Performance & Scalability — Features 0.1.1–1.1.1 R3 (PD-VAL-076)](validation/reports/performance-scalability/PD-VAL-076-performance-scalability-features-0.1.1-0.1.2-1.1.1.md) - Session 14 (Score: 2.7/3.0 PASS)
- [Validation: Performance & Scalability — Features 2.1.1–6.1.1 R3 (PD-VAL-078)](validation/reports/performance-scalability/PD-VAL-078-performance-scalability-features-2.1.1-2.2.1-6.1.1.md) - Session 15 (Score: 2.85/3.0 PASS)
- [Validation: Observability — Features 0.1.1–6.1.1 R3 (PD-VAL-080)](validation/reports/observability/PD-VAL-080-observability-features-0.1.1-1.1.1-3.1.1-6.1.1.md) - Session 16 (Score: 2.60/3.0 PASS)
- [Validation: Data Integrity — Features 0.1.2–6.1.1 R3 (PD-VAL-079)](validation/reports/data-integrity/PD-VAL-079-data-integrity-features-0.1.2-2.2.1-6.1.1.md) - Session 17 (Score: 2.61/3.0 PASS)

### Round 4 Validation Reports

- [Validation: Architectural Consistency — Features 0.1.1–1.1.1 R4 (PD-VAL-083)](validation/reports/architectural-consistency/PD-VAL-083-architectural-consistency-features-0.1.1-0.1.2-0.1.3-1.1.1.md) - Session 1 (Score: 2.88/3.0 PASS)
- [Validation: Code Quality — Features 0.1.1–1.1.1 R4 (PD-VAL-082)](validation/reports/code-quality/PD-VAL-082-code-quality-features-0.1.1-0.1.2-0.1.3-1.1.1.md) - Session 3 (Score: 2.75/3.0 PASS)
- [Validation: Integration Dependencies — Features 0.1.1–1.1.1 R4 (PD-VAL-081)](validation/reports/integration-dependencies/PD-VAL-081-integration-dependencies-features-0.1.1-0.1.2-0.1.3-1.1.1.md) - Session 5 (Score: 2.85/3.0 PASS)
- [Validation: Architectural Consistency — Features 2.1.1–6.1.1 R4 (PD-VAL-085)](validation/reports/architectural-consistency/PD-VAL-085-architectural-consistency-features-2.1.1-2.2.1-3.1.1-6.1.1.md) - Session 2 (Score: 2.70/3.0 PASS)
- [Validation: Integration Dependencies — Features 2.1.1–6.1.1 R4 (PD-VAL-086)](validation/reports/integration-dependencies/PD-VAL-086-integration-dependencies-features-2.1.1-2.2.1-3.1.1-6.1.1.md) - Session 6 (Score: 2.70/3.0 PASS)
- [Validation: Code Quality — Features 2.1.1–6.1.1 R4 (PD-VAL-084)](validation/reports/code-quality/PD-VAL-084-code-quality-features-2.1.1-2.2.1-3.1.1-6.1.1.md) - Session 4 (Score: 2.45/3.0 PASS)
- [Validation: Documentation Alignment — 0.1.1, 0.1.2, 0.1.3, 1.1.1 (PD-VAL-089)](validation/reports/documentation-alignment/PD-VAL-089-documentation-alignment-features-0.1.1-0.1.2-0.1.3-1.1.1.md) - Session 7
- [Validation: Documentation Alignment — 2.1.1, 2.2.1, 3.1.1, 6.1.1 R4 (PD-VAL-087)](validation/reports/documentation-alignment/PD-VAL-087-documentation-alignment-features-2.1.1-2.2.1-3.1.1-6.1.1.md) - Session 8 (Score: 2.75/3.0 PASS)
- [Validation: AI Agent Continuity — 2.1.1, 2.2.1, 3.1.1, 6.1.1 (PD-VAL-090)](validation/reports/ai-agent-continuity/PD-VAL-090-ai-agent-continuity-features-2.1.1-2.2.1-3.1.1-6.1.1.md) - Session 12
- [Validation: Extensibility & Maintainability — 0.1.1, 0.1.2, 0.1.3, 1.1.1 (PD-VAL-091)](validation/reports/extensibility-maintainability/PD-VAL-091-extensibility-maintainability-features-0.1.1-0.1.2-0.1.3-1.1.1.md) - Session 9
- [Validation: AI Agent Continuity — 0.1.1, 0.1.2, 0.1.3, 1.1.1 (PD-VAL-092)](validation/reports/ai-agent-continuity/PD-VAL-092-ai-agent-continuity-features-0.1.1-0.1.2-0.1.3-1.1.1.md) - Session 11
- [Validation: Extensibility & Maintainability — 2.1.1, 2.2.1, 3.1.1, 6.1.1 (PD-VAL-094)](validation/reports/extensibility-maintainability/PD-VAL-094-extensibility-maintainability-features-2.1.1-2.2.1-3.1.1-6.1.1.md) - Session 10
- [Validation: Observability — 0.1.1, 1.1.1, 3.1.1, 6.1.1 (PD-VAL-095)](validation/reports/observability/PD-VAL-095-observability-features-0.1.1-1.1.1-3.1.1-6.1.1.md) - Session 16
- [Validation: Performance & Scalability — 0.1.1, 0.1.2, 1.1.1 (PD-VAL-096)](validation/reports/performance-scalability/PD-VAL-096-performance-scalability-features-0.1.1-0.1.2-1.1.1.md) - Session 14
- [Validation: Performance & Scalability — 2.1.1, 2.2.1, 6.1.1 (PD-VAL-097)](validation/reports/performance-scalability/PD-VAL-097-performance-scalability-features-2.1.1-2.2.1-6.1.1.md) - Session 15
- [Validation: Data Integrity — 0.1.2, 2.2.1, 6.1.1 (PD-VAL-098)](validation/reports/data-integrity/PD-VAL-098-data-integrity-features-0.1.2-2.2.1-6.1.1.md) - Session 17
- [Validation: Security & Data Protection — 0.1.3, 1.1.1, 2.2.1, 6.1.1 (PD-VAL-099)](validation/reports/security-data-protection/PD-VAL-099-security-data-protection-features-0.1.3-1.1.1-2.2.1-6.1.1.md) - Session 13

## Maintaining This Documentation

When adding new product documentation:
1. Add the entry to the appropriate directory section in this map
2. Use local relative paths from `doc` (no `../doc/` prefix needed)
3. For process framework documents, add to [Process Framework Documentation Map](/process-framework/PF-documentation-map.md) instead
4. For test documents, add to [Test Documentation Map](/test/TE-documentation-map.md) instead
