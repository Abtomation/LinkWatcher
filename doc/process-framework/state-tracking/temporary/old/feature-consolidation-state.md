---
id: PF-STA-047
type: Process Framework
category: State Tracking
version: 1.0
created: 2026-02-20
updated: 2026-02-20
change_name: feature-scope-consolidation
---

# Structure Change State: Feature Scope Consolidation (42 → 9)

> **TEMPORARY FILE**: This file tracks the multi-session implementation of feature scope consolidation. Move to `doc/process-framework/state-tracking/temporary/old/` after all changes are implemented and validated.

## Structure Change Overview

- **Change Name**: Feature Scope Consolidation
- **Change Type**: Documentation Architecture / Feature Restructuring
- **Scope**: Consolidate 42 granular features into 9 coarse-grained features with matching documentation updates
- **Rationale**: Original onboarding discovery was over-granular — many "features" are implementation details of larger subsystems
- **Plan File**: `C:\Users\ronny\.claude\plans\adaptive-launching-rose.md`

## Consolidation Mapping

```
NEW 0.1.1: Core Architecture           ← OLD 0.1.1, 0.1.2, 0.1.5
NEW 0.1.2: In-Memory Link Database     ← OLD 0.1.3
NEW 0.1.3: Configuration System        ← OLD 0.1.4
NEW 1.1.1: File System Monitoring      ← OLD 1.1.1–1.1.5
NEW 2.1.1: Link Parsing System         ← OLD 2.1.1–2.1.7
NEW 2.2.1: Link Updating               ← OLD 2.2.1–2.2.5
NEW 3.1.1: Logging System              ← OLD 3.1.1–3.1.5
NEW 4.1.1: Test Suite                  ← OLD 4.1.1–4.1.8
NEW 5.1.1: CI/CD & Development Tooling ← OLD 5.1.1–5.1.7
```

## New Feature Definitions

| ID | Feature | Description | Key Files |
|----|---------|-------------|-----------|
| 0.1.1 | Core Architecture | Service orchestrator (facade pattern), data models, path utilities, CLI entry point | service.py, __init__.py, main.py, models.py, utils.py |
| 0.1.2 | In-Memory Link Database | Thread-safe, target-indexed link storage with O(1) lookups | database.py |
| 0.1.3 | Configuration System | Multi-source config loading (YAML/JSON/env/CLI), validation, environment presets | config/settings.py, config/defaults.py, config/__init__.py, config-examples/* |
| 1.1.1 | File System Monitoring | Watchdog event handling, move detection (delete+create pairing), directory moves, file filtering | handler.py |
| 2.1.1 | Link Parsing System | Parser registry/facade with 6 format-specific parsers (Markdown, YAML, JSON, Python, Dart, Generic) | parser.py, parsers/* (8 files) |
| 2.2.1 | Link Updating | Reference updating with relative path calculation, atomic writes, backup creation, dry-run mode | updater.py |
| 3.1.1 | Logging System | Structured logging with colored console output, JSON file logging, rotating handlers, runtime filtering, performance metrics | logging.py, logging_config.py |
| 4.1.1 | Test Suite | Pytest-based infrastructure with 247+ tests (unit, integration, parser, performance), fixtures, test utilities | tests/*, run_tests.py, pytest.ini |
| 5.1.1 | CI/CD & Development Tooling | GitHub Actions pipeline, pre-commit hooks, startup scripts, debug tools, benchmarks, deployment scripts | .github/workflows/*, .pre-commit-config.yaml, LinkWatcher_run/*, deployment/*, scripts/*, tools/*, debug/*, examples/*, manual_markdown_tests/* |

---

## Existing Artifact Inventory

### FDDs (12 existing)

| Doc ID | Old Feature ID | Feature Name | File | New Feature Target |
|--------|---------------|-------------|------|--------------------|
| PD-FDD-022 | 0.1.1 | Core Architecture | fdd-0-1-1-core-architecture.md | **0.1.1** — Update scope |
| PD-FDD-023 | 0.1.3 | In-Memory Database | fdd-0-1-3-in-memory-database.md | **0.1.2** — Rename + update ID |
| PD-FDD-024 | 1.1.2 | Event Handler | fdd-1-1-2-event-handler.md | **1.1.1** — Rename + expand scope |
| PD-FDD-025 | 3.1.1 | Logging Framework | fdd-3-1-1-logging-framework.md | **3.1.1** — Expand scope |
| PD-FDD-026 | 2.1.1 | Parser Framework | fdd-2-1-1-parser-framework.md | **2.1.1** — Expand scope |
| PD-FDD-027 | 2.2.1 | Link Updater | fdd-2-2-1-link-updater.md | **2.2.1** — Expand scope |
| PD-FDD-028 | 4.1.1 | Test Framework | fdd-4-1-1-test-framework.md | **4.1.1** — Merge primary |
| PD-FDD-029 | 4.1.3 | Integration Tests | fdd-4-1-3-integration-tests.md | **4.1.1** — Merge into PD-FDD-028 |
| PD-FDD-030 | 4.1.4 | Parser Tests | fdd-4-1-4-parser-tests.md | **4.1.1** — Merge into PD-FDD-028 |
| PD-FDD-031 | 4.1.6 | Test Fixtures | fdd-4-1-6-test-fixtures.md | **4.1.1** — Merge into PD-FDD-028 |
| PD-FDD-032 | 5.1.1 | GitHub Actions CI | fdd-5-1-1-github-actions-ci.md | **5.1.1** — Merge primary |
| PD-FDD-033 | 5.1.2 | Test Automation | fdd-5-1-2-test-automation.md | **5.1.1** — Merge into PD-FDD-032 |

### TDDs (12 existing)

| Doc ID | Old Feature ID | Feature Name | File | New Feature Target |
|--------|---------------|-------------|------|--------------------|
| PD-TDD-021 | 0.1.1 | Core Architecture | tdd-0-1-1-core-architecture-t3.md | **0.1.1** — Update scope |
| PD-TDD-022 | 0.1.3 | In-Memory Database | tdd-0.1.3-in-memory-database-t2.md | **0.1.2** — Rename + update ID |
| PD-TDD-023 | 1.1.2 | Event Handler | tdd-1-1-2-event-handler-t2.md | **1.1.1** — Rename + expand scope |
| PD-TDD-024 | 3.1.1 | Logging Framework | tdd-3-1-1-logging-framework-t2.md | **3.1.1** — Expand scope |
| PD-TDD-025 | 2.1.1 | Parser Framework | tdd-2-1-1-parser-framework-t2.md | **2.1.1** — Expand scope |
| PD-TDD-026 | 2.2.1 | Link Updater | tdd-2-2-1-link-updater-t2.md | **2.2.1** — Expand scope |
| PD-TDD-027 | 4.1.1 | Test Framework | tdd-4-1-1-test-framework-t2.md | **4.1.1** — Merge primary |
| PD-TDD-028 | 4.1.3 | Integration Tests | tdd-4-1-3-integration-tests-t2.md | **4.1.1** — Merge into PD-TDD-027 |
| PD-TDD-029 | 4.1.4 | Parser Tests | tdd-4-1-4-parser-tests-t2.md | **4.1.1** — Merge into PD-TDD-027 |
| PD-TDD-030 | 4.1.6 | Test Fixtures | tdd-4-1-6-test-fixtures-t2.md | **4.1.1** — Merge into PD-TDD-027 |
| PD-TDD-031 | 5.1.1 | GitHub Actions CI | tdd-5-1-1-github-actions-ci-t2.md | **5.1.1** — Merge primary |
| PD-TDD-032 | 5.1.2 | Test Automation | tdd-5-1-2-test-automation-t2.md | **5.1.1** — Merge into PD-TDD-031 |

### ADRs (2 existing)

| Doc ID | Old Feature ID | Feature Name | File | Action |
|--------|---------------|-------------|------|--------|
| PD-ADR-039 | 0.1.1 | Orchestrator/Facade Pattern | orchestrator-facade-pattern-for-core-architecture.md | Keep as-is (ID unchanged) |
| PD-ADR-040 | 0.1.3 | Target-Indexed Database | target-indexed-in-memory-link-database.md | Update feature ref 0.1.3 → 0.1.2 |

### Test Specifications (1 existing)

| Doc ID | Old Feature ID | Feature Name | File | Action |
|--------|---------------|-------------|------|--------|
| PF-TSP-035 | 0.1.1 | Core Architecture | test-spec-0-1-1-core-architecture.md | Update scope (add models.py, utils.py) |

### Tier Assessments (42 existing)

| ID Range | Location | Action |
|----------|----------|--------|
| ART-ASS-148 through ART-ASS-190 | doc/process-framework/methodologies/documentation-tiers/assessments/ | Archive all, create 9 new consolidated assessments |

---

## Implementation Roadmap

### Phase 1: Feature Tracking Rewrite

- [x] **1.1** Rewrite `feature-tracking.md` with 9 consolidated features
  - **Status**: COMPLETED
  - **File**: `doc/process-framework/state-tracking/permanent/feature-tracking.md`
  - **Action**: Complete rewrite — 9 features with new descriptions, key files, and linked artifacts
  - **Notes**: Each feature links to all relevant FDDs, TDDs, ADRs, test specs

### Phase 2: FDD Consolidation

#### 2a. FDD In-Place Updates (expand scope)

- [x] **2a.1** Update FDD-022: Core Architecture — add models.py (old 0.1.2) and utils.py (old 0.1.5) scope
  - **Status**: COMPLETED
  - **File**: `doc/product-docs/functional-design/fdds/fdd-0-1-1-core-architecture.md`

- [x] **2a.2** Update FDD-026: Parser Framework — add individual parsers (old 2.1.2–2.1.7) scope
  - **Status**: COMPLETED
  - **File**: `doc/product-docs/functional-design/fdds/fdd-2-1-1-parser-framework.md`

- [x] **2a.3** Update FDD-027: Link Updater — add relative paths, anchors, dry-run, backup (old 2.2.2–2.2.5) scope
  - **Status**: COMPLETED
  - **File**: `doc/product-docs/functional-design/fdds/fdd-2-2-1-link-updater.md`

- [x] **2a.4** Update FDD-025: Logging Framework — add colored output, stats, progress, errors (old 3.1.2–3.1.5) scope
  - **Status**: COMPLETED
  - **File**: `doc/product-docs/functional-design/fdds/fdd-3-1-1-logging-framework.md`

#### 2b. FDD Renames (feature ID changes)

- [x] **2b.1** Rename FDD-023: `fdd-0-1-3-in-memory-database.md` → `fdd-0-1-2-in-memory-database.md` — update feature ID 0.1.3 → 0.1.2
  - **Status**: COMPLETED
  - **Notes**: File renamed, feature_id and feature_name updated in metadata

- [x] **2b.2** Rename FDD-024: `fdd-1-1-2-event-handler.md` → `fdd-1-1-1-file-system-monitoring.md` — update feature ID 1.1.2 → 1.1.1, expand scope to full monitoring system
  - **Status**: COMPLETED
  - **Notes**: File renamed, feature_id updated, consolidates metadata added

#### 2c. FDD Merges (multiple docs → one)

- [x] **2c.1** Merge FDD-028 + FDD-029 + FDD-030 + FDD-031 → `fdd-4-1-1-test-suite.md` — rename FDD-028, merge content from 029/030/031, delete originals
  - **Status**: COMPLETED
  - **Source files**: fdd-4-1-1-test-framework.md, fdd-4-1-3-integration-tests.md, fdd-4-1-4-parser-tests.md, fdd-4-1-6-test-fixtures.md
  - **Target**: fdd-4-1-1-test-suite.md

- [x] **2c.2** Merge FDD-032 + FDD-033 → `fdd-5-1-1-cicd-development-tooling.md` — rename FDD-032, merge content from 033, delete original
  - **Status**: COMPLETED
  - **Source files**: fdd-5-1-1-github-actions-ci.md, fdd-5-1-2-test-automation.md
  - **Target**: fdd-5-1-1-cicd-development-tooling.md

### Phase 3: TDD Consolidation

#### 3a. TDD In-Place Updates (expand scope)

- [x] **3a.1** Update TDD-021: Core Architecture — add models.py + utils.py scope
  - **Status**: COMPLETED
  - **File**: `doc/product-docs/technical/architecture/design-docs/tdd/tdd-0-1-1-core-architecture-t3.md`

- [x] **3a.2** Update TDD-025: Parser Framework — add individual parsers scope
  - **Status**: COMPLETED
  - **File**: `doc/product-docs/technical/architecture/design-docs/tdd/tdd-2-1-1-parser-framework-t2.md`

- [x] **3a.3** Update TDD-026: Link Updater — add sub-features scope
  - **Status**: COMPLETED
  - **File**: `doc/product-docs/technical/architecture/design-docs/tdd/tdd-2-2-1-link-updater-t2.md`

- [x] **3a.4** Update TDD-024: Logging Framework — add sub-features scope
  - **Status**: COMPLETED
  - **File**: `doc/product-docs/technical/architecture/design-docs/tdd/tdd-3-1-1-logging-framework-t2.md`

#### 3b. TDD Renames (feature ID changes)

- [x] **3b.1** Rename TDD-022: `tdd-0.1.3-in-memory-database-t2.md` → `tdd-0-1-2-in-memory-database-t2.md` — fix dot notation, update feature ID
  - **Status**: COMPLETED
  - **Notes**: File renamed, dot notation fixed, feature_id updated to 0.1.2

- [x] **3b.2** Rename TDD-023: `tdd-1-1-2-event-handler-t2.md` → `tdd-1-1-1-file-system-monitoring-t2.md` — update feature ID, expand scope
  - **Status**: COMPLETED
  - **Notes**: File renamed, feature_id updated to 1.1.1, consolidates metadata added

#### 3c. TDD Merges (multiple docs → one)

- [x] **3c.1** Merge TDD-027 + TDD-028 + TDD-029 + TDD-030 → `tdd-4-1-1-test-suite-t2.md` — rename TDD-027, merge content, delete originals
  - **Status**: COMPLETED
  - **Target**: tdd-4-1-1-test-suite-t2.md
  - **Notes**: Merged all 4 TDDs, deleted originals

- [x] **3c.2** Merge TDD-031 + TDD-032 → `tdd-5-1-1-cicd-development-tooling-t2.md` — rename TDD-031, merge content, delete original
  - **Status**: COMPLETED
  - **Target**: tdd-5-1-1-cicd-development-tooling-t2.md
  - **Notes**: Merged both TDDs, deleted originals

### Phase 4: ADR & Test Spec Updates

- [x] **4.1** Update ADR-040: Change feature ID reference from 0.1.3 → 0.1.2
  - **Status**: COMPLETED
  - **File**: `doc/product-docs/technical/architecture/design-docs/adr/adr/target-indexed-in-memory-link-database.md`
  - **Notes**: Updated feature_id, feature_name, and FDD/TDD cross-references to renamed files

- [x] **4.2** Update Test Spec PF-TSP-035: Expand scope to include models.py, utils.py
  - **Status**: COMPLETED
  - **File**: `test/specifications/feature-specs/test-spec-0-1-1-core-architecture.md`
  - **Notes**: Added consolidated scope note, added coverage gaps for models.py and utils.py

### Phase 5: Assessment Consolidation

- [x] **5.1** Create archive directory: `doc/process-framework/methodologies/documentation-tiers/assessments/archive/`
  - **Status**: COMPLETED

- [x] **5.2** Move all 42 old assessment files (ART-ASS-148–190) to archive directory
  - **Status**: COMPLETED
  - **Notes**: All 42 files moved to archive/

- [x] **5.3** Create 9 new consolidated tier assessments (ART-ASS-191 through ART-ASS-199)
  - **Status**: COMPLETED
  - **Notes**: 1 Tier 3, 7 Tier 2, 1 Tier 1

### Phase 6: Feature State Files Cleanup

- [x] **6.1** Confirm deletion of all 42 old feature state files in `doc/process-framework/state-tracking/features/`
  - **Status**: COMPLETED
  - **Notes**: Directory is empty — files were already deleted. Staged for deletion in git.

### Phase 7: Documentation Updates

- [x] **7.1** Update `doc/process-framework/documentation-map.md` — replace all retrospective sections with 9 consolidated entries
  - **Status**: COMPLETED
  - **Notes**: Updated FDD, TDD, ADR, Test Spec sections; version bumped to 2.0

- [x] **7.2** Update `doc/id-registry.json` — update ART-ASS nextAvailable to 200
  - **Status**: COMPLETED
  - **Notes**: Updated timestamp and ART-ASS nextAvailable counter

- [x] **7.3** Cross-reference sweep — grep for old feature IDs and update remaining references
  - **Status**: COMPLETED
  - **Fixed**: TDD-022 FDD link, TDD-023 FDD link + dependency IDs, test-implementation-tracking.md (all old feature IDs), technical-debt-tracking.md (old feature state links)

### Phase 8: Validation

- [x] **8.1** Verify feature-tracking.md lists exactly 9 features with correct links
  - **Status**: COMPLETED — PASS

- [x] **8.2** Verify each FDD/TDD file exists at expected path and has correct feature ID
  - **Status**: COMPLETED — PASS (8 FDDs + 8 TDDs, all correct)

- [x] **8.3** Verify documentation-map.md has no broken references
  - **Status**: COMPLETED — PASS (8 FDD + 8 TDD entries, all valid)

- [x] **8.4** Verify no old feature IDs remain outside archive
  - **Status**: COMPLETED — PASS (only expected metadata references in consolidation tracking files)

---

## Session Tracking

### Session 1: 2026-02-20
**Focus**: Planning & Phases 1–3
**Completed**:
- Created consolidation plan and this state tracking file
- Phase 1: Feature tracking rewrite (42→9)
- Phase 2: FDD consolidation (in-place updates, renames, merges)
- Phase 3: TDD consolidation (in-place updates, renames, merges)

### Session 2: 2026-02-20 (continued)
**Focus**: Phases 4–8 (completion)
**Completed**:
- Fixed 4 broken links in feature-tracking.md from prior session
- Phase 4: ADR-040 feature ID update, Test Spec scope expansion
- Phase 5: Archived 42 old assessments, created 9 new (ART-ASS-191–199)
- Phase 6: Confirmed feature state files deletion
- Phase 7: Updated documentation-map.md, id-registry.json, cross-reference sweep (test tracking, tech debt tracking, TDD internal links)
- Phase 8: All 6 validation checks PASS

**Result**: Feature consolidation COMPLETE. All 8 phases done.

---

## Key Decisions

1. **FDD/TDD merge strategy**: Merge multi-doc features into single consolidated documents (user decision)
2. **Assessment handling**: Archive old 42 assessments, create 9 new consolidated ones (user decision)
3. **Path Utilities mapping**: OLD 0.1.5 → NEW 0.1.1 (Core Architecture), not Configuration System, per user's file assignment
4. **Feature state files**: Delete all 42, do not create new ones since all features are fully implemented
5. **Document IDs**: Keep original PD-FDD/PD-TDD IDs stable — merged-away IDs noted as archived

## Notes

- LinkWatcher must be running during file renames (Phases 2b, 3b) to auto-update cross-references
- Configuration System (NEW 0.1.3) has no existing FDD/TDD — old 0.1.4 only had a tier assessment. Mark as "Documentation TBD" in feature tracking.
