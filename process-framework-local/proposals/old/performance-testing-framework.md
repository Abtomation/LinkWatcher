---
id: PF-PRO-017
type: Document
category: General
version: 2.0
created: 2026-04-08
updated: 2026-04-08
extension_description: Cohesive performance testing framework with dedicated lifecycle, trend tracking, and clean interfaces to existing tasks
extension_name: Performance Testing Framework
extension_scope: Performance testing artifacts, workflows, tasks, and infrastructure — separate lifecycle from functional testing with defined interfaces
---

# Performance Testing Framework - Framework Extension Concept

## Document Metadata
| Metadata | Value |
|----------|-------|
| Document Type | Framework Extension Concept |
| Created Date | 2026-04-08 |
| Status | Awaiting Human Review |
| Extension Name | Performance Testing Framework |
| Extension Scope | Performance testing artifacts, workflows, tasks, and infrastructure |
| Author | AI Agent & Human Partner |
| Source | [PF-EVR-010](../../evaluation-reports/20260408-framework-evaluation-performance-testing-support-targeted-evaluation-of.md), PF-IMP-416 |

---

## 🔀 Extension Type

**Selected Type**: Hybrid

Creates new artifacts (guide, tasks, tracking file, results DB, templates) and modifies existing ones (Definition of Done, task definitions, config).

---

## 🎯 Purpose & Context

**Brief Description**: Establish performance testing as a distinct discipline within the framework — with its own lifecycle, tracking, trend analysis, and methodology — rather than treating it as a variant of functional testing.

### Extension Overview

The framework currently has basic performance testing plumbing — 2 test files (10 methods), working scripts (`Run-Tests.ps1 -Performance`, `New-TestFile.ps1`), and a validation task (PF-TSK-073). However, it lacks the strategic layer: no baselines, no dedicated guide, no trend tracking, no formalized test levels, and no clear workflow for creating or maintaining performance tests.

**Key design decisions** (established during concept development):

1. **Performance tests are cross-cutting, not feature-owned.** They don't map cleanly to the feature-based tracking in test-tracking.md. They get their own tracking file.

2. **Four test levels** adapted to LinkWatcher's architecture (not generic industry categories):
   - **Component benchmarks** — isolated subsystem throughput (parser, DB, detector, updater)
   - **Operation benchmarks** — cross-cutting operations end-to-end (scan, move handling, validation)
   - **Scale tests** — operations under extreme conditions (1000+ files, deep dirs, many refs, rapid moves)
   - **Resource bounds** — system-wide constraints (memory, CPU)

3. **Separate lifecycle from functional testing.** Performance test creation, baseline capture, and trend analysis are distinct tasks — not shoehorned into Integration & Testing or Test Audit.

4. **Clean interfaces to existing tasks** rather than modifying their internals. Existing tasks route to performance tasks at defined trigger points.

### Key Distinction from Existing Framework Components

| Existing Component | Purpose | Scope |
|-------------------|---------|-------|
| **Integration & Testing (PF-TSK-053)** | Create functional tests alongside implementation | Unit, component, integration, e2e tests — feature-scoped |
| **Test Audit (PF-TSK-030)** | Evaluate functional test quality | 6 criteria for functional test adequacy |
| **Performance Testing Framework** *(This Extension)* | **Dedicated performance testing lifecycle** | **Cross-cutting performance tests with baselines, trend tracking, and distinct methodology** |

---

## 🏗️ Architecture: Test Levels

### Level Definitions

| Level | What it measures | Threshold type | Example |
|-------|-----------------|----------------|---------|
| **Component** | Single subsystem in isolation | Throughput (ops/sec, files/sec) | Parser: >50 files/sec for 100 mixed-format files |
| **Operation** | Cross-cutting operation end-to-end | Latency (seconds for N items) | Initial scan of 100 files: <2s |
| **Scale** | Operations under extreme conditions | Pass/fail at threshold | 1000-file scan completes within 30s |
| **Resource** | System-wide constraints | Ceiling (MB, CPU%) | RSS stays under 100MB for 200 files |

### Current Test Coverage by Level

| Level | Existing Tests | Gaps |
|-------|---------------|------|
| Component | BM-001 (parser), BM-002 (DB) | Updater throughput, move detector timing |
| Operation | BM-003 (initial scan) | Validation mode, file move end-to-end latency |
| Scale | PH-001 (1000 files), PH-002 (deep dirs), PH-003 (large files), PH-004 (many refs), PH-005 (rapid moves) | Directory batch detection at scale |
| Resource | Memory monitoring, CPU monitoring | — (adequate) |

### Link to Feature Tiers

Features don't own performance tests. Instead, feature changes **trigger** performance test activities:

- Feature changes a hot-path component → **update relevant Component benchmarks**
- Feature changes an end-to-end operation → **verify Operation benchmarks don't regress**
- Feature changes scaling characteristics → **update Scale tests**

The trigger is encoded in the **Definition of Done** and **PF-TSK-053 routing**.

---

## 🔄 New Tasks

### Task 1: Performance Test Creation

**Purpose**: Implement performance tests from a performance test specification — proper measurement design, threshold-setting against baselines, registration in performance-test-tracking.

**When triggered**:
- PF-TSK-033 (Test Spec Creation) produces a performance test spec with PE dimension requirements
- Standalone when adding performance coverage for untested areas identified in the cross-cutting spec
- When performance-test-tracking.md has `⬜ Specified` entries that need implementation

**Inputs**: Performance Test Specification (what to test — from PF-TSK-033), Performance Testing Guide (how to test), Performance Test Tracking (existing baselines + specified-but-not-created entries)

**Process**:
1. Read the performance test spec and performance-test-tracking.md
2. Pre-populate tracking with `⬜ Specified` rows for all tests defined in the spec that don't have entries yet
3. Implement tests, updating each row from `⬜ Specified` → `📋 Created`
4. If session ends before all tests are created, remaining `⬜ Specified` rows are visible for the next session

**Outputs**: New/updated test files, updated Performance Test Tracking entries (⬜ → 📋)

**Why separate from PF-TSK-053**: Performance tests require baseline methodology, level selection, and cross-cutting thinking. PF-TSK-053 creates feature-scoped functional tests — different methodology, different tracking, different audit criteria. Planning stays in PF-TSK-033; execution splits by test type.

### Task 2: Performance Baseline Capture

**Location**: `process-framework/tasks/03-testing/` (testing task, not cyclical — even though triggered repeatedly)

**Purpose**: Run performance tests, record results in trend database, update tracking file with latest values, flag regressions.

**When triggered**:
- After Performance Test Creation (new tests need initial baselines)
- After code changes to hot paths (verify no regression)
- Pre-release verification
- Periodic health check

**Inputs**: Performance test suite, Performance Test Tracking (expected baselines), Results Database (historical trend)

**Outputs**: Updated Performance Test Tracking (latest values), new entries in Results Database, regression report (if any)

**Why separate**: No existing task covers "run tests and record results for trend analysis." This is a lightweight recurring activity with its own methodology (statistical comparison, trend interpretation).

---

## 📊 New Artifacts

### Performance Test Tracking File

**Location**: `test/state-tracking/permanent/performance-test-tracking.md`

Combined registry + baselines + last result + lifecycle status. Single source of truth for performance tests (replaces entries in test-tracking.md).

**Lifecycle** (mirrors E2E pattern from e2e-test-tracking.md):

| Status | Description | Set By |
|--------|-------------|--------|
| ⬜ **Specified** | Defined in performance test spec but not yet implemented | Performance Test Creation (pre-populates from spec) |
| 📋 **Created** | Test exists, no baseline captured yet | Performance Test Creation (after implementing test) |
| ✅ **Baselined** | Test exists with current baseline in results DB | Performance Baseline Capture |
| ⚠️ **Stale** | Baseline older than threshold or code changed since last capture | Manual / Baseline Capture (flags outdated entries) |

This lifecycle solves multi-session visibility: PF-TSK-033 produces a spec, Performance Test Creation pre-populates all planned tests as `⬜ Specified`, then works through them. The next session sees what's still `⬜`.

**Table structure**:

| Test ID | Level | Operation | Related Features | Status | Baseline | Tolerance | Last Result | Last Run | Test File | Spec Ref |
|---------|-------|-----------|-----------------|--------|----------|-----------|-------------|----------|-----------|----------|
| BM-001 | Component | Parser throughput (100 files) | 2.1.1 | ✅ Baselined | 420 files/sec | >50 files/sec | 435 files/sec | 2026-04-08 | test_benchmark.py | — |
| BM-002 | Component | DB add/lookup/update (1000 refs) | 0.1.2 | ✅ Baselined | 0.12s / 0.08s / 0.09s | <5s / <2s / <2s | 0.11s / 0.07s / 0.08s | 2026-04-08 | test_benchmark.py | — |
| BM-003 | Operation | Initial scan (100 files) | 0.1.1, 2.1.1, 0.1.2 | ✅ Baselined | 1.8s | <10s | 1.7s | 2026-04-08 | test_benchmark.py | — |
| PH-001 | Scale | Scan + move (1000 files) | 0.1.1, 1.1.1, 2.2.1 | ✅ Baselined | 8.2s scan, 0.4s move | <30s scan, <5s move | 7.9s, 0.3s | 2026-04-08 | test_large_projects.py | — |
| BM-004 | Component | Updater throughput | 2.2.1 | ⬜ Specified | — | — | — | — | — | TE-TSP-XXX §3.1 |
| BM-005 | Operation | Validation mode (100 files) | 0.1.1, 2.1.1 | ⬜ Specified | — | — | — | — | — | TE-TSP-XXX §4.2 |

**Related Features** maps which features' code affects each test. When code changes touch a feature, run the performance tests with matching feature IDs — not the entire suite.

### Performance Results Database

**Location**: `test/state-tracking/permanent/performance-results.db` (SQLite)
**Script**: `process-framework/scripts/test/performance_db.py`

Similar pattern to `feedback_db.py` — a Python script with subcommands:

```bash
# Record results after a test run
python process-framework/scripts/test/performance_db.py record --test-id BM-001 --value 435 --unit "files/sec"

# Batch record from pytest output (parses structured output)
python process-framework/scripts/test/performance_db.py record --from-output test-results.json

# Query trend for a specific test
python process-framework/scripts/test/performance_db.py trend --test-id BM-001 --last 10

# Show all regressions (latest result exceeds tolerance)
python process-framework/scripts/test/performance_db.py regressions

# Export trend data (for external visualization if needed)
python process-framework/scripts/test/performance_db.py export --format csv
```

Schema:
```sql
CREATE TABLE results (
    id INTEGER PRIMARY KEY,
    test_id TEXT NOT NULL,
    value REAL NOT NULL,
    unit TEXT NOT NULL,
    timestamp TEXT NOT NULL,
    git_commit TEXT,
    notes TEXT
);
```

### Performance Testing Guide

**Location**: `process-framework/guides/03-testing/performance-testing-guide.md`

Structure:
1. **Performance Test Levels** — definitions, when each level applies, threshold types
2. **When to Create Performance Tests** — decision matrix tied to feature tier and PE dimension
3. **How to Write Performance Tests** — measurement methodology, statistical considerations, avoiding flaky benchmarks
4. **Baseline Management** — how to set initial baselines, when to update, tolerance bands
5. **Trend Analysis** — using the results database, interpreting trends, when to act

### Performance Test Spec Template

**Location**: `process-framework/templates/03-testing/performance-test-specification-template.md`

Distinct from functional test spec template:
- Level-specific success criteria sections (Component, Operation, Scale, Resource)
- Baseline references column
- Measurement methodology section
- Tolerance/range criteria instead of pass/fail

### Cross-cutting Performance Test Specification

**Location**: `test/specifications/cross-cutting-specs/`

Consolidates scattered performance mentions from feature test specs into one authoritative spec organized by level.

---

## 🔗 Interfaces to Existing Tasks

Performance testing connects to the existing framework at defined points — **routing to** the new tasks, not modifying the internals of existing tasks.

### Trigger Chain

```
Test Spec Creation (PF-TSK-033) → PE dimension applicable?
    ├─ Functional dimensions → functional test spec → PF-TSK-053 (creates functional tests)
    └─ PE dimension → performance test spec → Performance Test Creation (creates perf tests)
                                                    ↓
                                            Performance Baseline Capture (records results, detects regressions)
                                                    ↓
Release & Deployment → "verify no regressions via Baseline Capture output"
```

**Planning responsibility**: PF-TSK-033 (Test Spec Creation) is the single entry point for planning what to test — for both functional and performance tests. When PE dimension is applicable, PF-TSK-033 uses the Performance Test Spec Template to plan which levels/operations need testing. The output feeds the Performance Test Creation task for execution.

**Post-implementation triggers**: After code changes to hot paths or after new performance tests are created, run Performance Baseline Capture to record results and detect regressions.

### Interface Points

| Existing Task | Interface | Change |
|--------------|-----------|--------|
| **Test Spec Creation (PF-TSK-033)** | PE dimension planning | Add: "PE dimension → use Performance Test Spec Template → output feeds Performance Test Creation task" |
| **Integration & Testing (PF-TSK-053)** | Step 5 PE clause | Remove PE clause from dimension examples (PE is handled entirely by TSK-033 → Performance Test Creation → Baseline Capture). Keep DI and SE clauses. |
| **Test Audit (PF-TSK-030)** | No change | Performance tests have their own lifecycle; functional test audit stays focused on functional tests |
| **Definition of Done** | Performance section | Replace UI criteria with: "No regression in Operation benchmarks (verified via Baseline Capture)" |
| **Release & Deployment (PF-TSK-007)** | Pre-release checklist | Add: "Run Baseline Capture, verify no regressions against trend" |
| **Code Refactoring (PF-TSK-022)** | Post-refactoring | Add: "If performance-affecting → trigger Baseline Capture" |

### What Does NOT Change

- **Test Audit (PF-TSK-030)** stays focused on functional test quality. Performance test adequacy is evaluated through baseline currency and trend analysis in the Baseline Capture task, not through the 6-criterion functional audit. A formal performance test audit could be a future extension once the practice matures.
- **test-tracking.md** — performance tests are removed (they never fit there). They live exclusively in performance-test-tracking.md.
- **Feature state files** — no performance test ownership. Features trigger performance testing; they don't own it.

### Tracking File Population

- **Initial (this extension, Session 1)**: Migrate all existing performance tests into performance-test-tracking.md as `✅ Baselined` (with measured baselines). One-time migration.
- **Ongoing — planning**: Performance Test Creation pre-populates `⬜ Specified` rows from a performance test spec (produced by PF-TSK-033). Multi-session progress is visible: `⬜` = still to do.
- **Ongoing — implementation**: Performance Test Creation updates rows from `⬜ Specified` → `📋 Created` as tests are implemented.
- **Ongoing — baselining**: Performance Baseline Capture updates rows from `📋 Created` → `✅ Baselined` and refreshes existing `✅` entries with latest results.

---

## 🔄 Modification-Focused Sections

### State Tracking Audit

| State File | Current Purpose | Modification Needed | Change Type |
|-----------|-----------------|---------------------|-------------|
| test-tracking.md | Functional test tracking per feature | Remove performance test entries (they move to performance-test-tracking.md) | Remove rows |
| process-improvement-tracking.md | IMP lifecycle tracking | Close PF-IMP-416 on completion | Status transition |

**Cross-reference impact**: Removing perf test rows from test-tracking.md may affect Validate-TestTracking.ps1 if it expects those rows. Need to verify during implementation.

### Guide Update Inventory

| File to Update | References To | Update Needed |
|---------------|---------------|---------------|
| Definition of Done | Performance criteria (Section 8) | Replace UI-centric criteria with CLI criteria + "no regression verified via Baseline Capture" |
| Test Spec Creation task (PF-TSK-033) | PE dimension mention | Add: "PE dimension → use Performance Test Spec Template → output feeds Performance Test Creation task" |
| Integration & Testing task (PF-TSK-053, Step 5) | "Critical PE → include performance regression tests" | Remove PE clause from dimension examples. Keep DI and SE. |

**Discovery method**: PF-EVR-010 findings + grep for "performance" across tasks/ and guides/.

### Automation Integration Strategy

| Existing Script | Current Behavior | Required Change | Backward Compatible? |
|----------------|-----------------|-----------------|---------------------|
| Run-Tests.ps1 | `-Performance` uses `slow` marker | Add `performance` marker support | Yes — additive |
| New-TestFile.ps1 | Supports Performance type | None — already works | N/A |
| Validate-TestTracking.ps1 | Validates test-tracking.md | May need update if perf test rows are removed | Check during implementation |

**New automation needed**:
- `performance_db.py` — record/query/export performance results (SQLite)
- Script or pytest plugin to auto-record results after test runs (optional, could be manual initially)

---

## 🔧 Implementation Roadmap

### Required Components

#### New Tasks

| Task | Location | Purpose |
|------|----------|---------|
| Performance Test Creation | `tasks/03-testing/` | Implement performance tests from specs, register in tracking, capture initial baselines |
| Performance Baseline Capture | `tasks/03-testing/` | Run tests, record results in trend DB, update tracking, flag regressions |

#### New Artifacts

| Component | Type | Priority |
|-----------|------|----------|
| Performance Testing Guide | Guide | HIGH |
| Performance Test Tracking file | State file | HIGH |
| Performance Results Database + script | Script + DB | HIGH |
| Performance Test Spec Template | Template | MEDIUM |
| Cross-cutting Performance Test Spec | Test spec | MEDIUM |
| Performance Test Creation task definition | Task (03-testing) | HIGH |
| Performance Baseline Capture task definition | Task (03-testing) | HIGH |

#### Existing Artifact Modifications

| Artifact | Priority |
|----------|----------|
| Definition of Done Section 8 | HIGH |
| PF-TSK-053 Step 5 routing | MEDIUM |
| PF-TSK-033 PE dimension routing | MEDIUM |
| python-config.json `performance` marker | LOW |
| test-tracking.md (remove perf test rows) | LOW |

### Multi-Session Implementation Plan

#### Session 1: Foundation — Guide + Tracking Infrastructure
**Priority**: HIGH — Everything else depends on the guide and tracking
- [ ] Create Performance Testing Guide (4 levels, methodology, decision matrix)
- [ ] Create Performance Test Tracking file with current test inventory + measured baselines
- [ ] Create `performance_db.py` script with record/trend/regressions subcommands
- [ ] Run existing tests, capture initial baselines, populate tracking + DB
- [ ] Update Definition of Done Section 8

#### Session 2: Tasks + Templates
**Priority**: HIGH — Tasks define the workflow; template enables specs
- [ ] Create Performance Test Creation task definition (via New-Task.ps1 + customization)
- [ ] Create Performance Baseline Capture task definition (via New-Task.ps1 + customization)
- [ ] Create Performance Test Spec Template (via New-Template.ps1 + customization)
- [ ] Update ai-tasks.md with new tasks
- [ ] Update PF-TSK-053 Step 5 with routing to Performance Test Creation
- [ ] Update PF-TSK-033 with PE dimension routing

#### Session 3: Test Specification + Coverage Expansion
**Priority**: MEDIUM — Depends on guide and template from Sessions 1-2
- [ ] Create cross-cutting Performance Test Specification using new template
- [ ] Implement new performance tests: file update throughput, delete+create correlation timing, validation mode performance, directory batch detection
- [ ] Capture baselines for new tests (run Baseline Capture workflow)
- [ ] Update python-config.json with `performance` marker

#### Session 4: Integration + Finalization
**Priority**: MEDIUM — Cross-references, verification, cleanup
- [ ] Remove performance test entries from test-tracking.md
- [ ] Update documentation maps (PF-documentation-map.md, TE-documentation-map.md)
- [ ] Update Release & Deployment task with Baseline Capture reference
- [ ] Update Code Refactoring task with Baseline Capture trigger
- [ ] Run Validate-StateTracking.ps1, fix any issues
- [ ] Close PF-IMP-416 via Update-ProcessImprovement.ps1
- [ ] Complete feedback form

---

## 🎯 Success Criteria

### Functional
- [ ] Performance Testing Guide covers all 4 levels with decision matrix for when to test
- [ ] Performance Test Tracking file contains all existing performance tests with measured baselines
- [ ] Results Database populated with initial baseline measurements; `trend` and `regressions` commands work
- [ ] Two new task definitions created with clear trigger conditions and interfaces
- [ ] Definition of Done Section 8 contains CLI-relevant criteria
- [ ] PF-TSK-053 Step 5 routes to Performance Test Creation (not vague "include perf tests")
- [ ] At least 3 new performance tests covering previously untested areas
- [ ] Cross-cutting Performance Test Spec consolidates scattered requirements

### Quality
- [ ] Validate-StateTracking.ps1 passes with no new failures
- [ ] All new artifacts follow naming conventions and metadata patterns
- [ ] Performance guide is actionable: a new contributor can create a performance test by following it alone
- [ ] Trigger chain is explicit and traceable through task definitions

### Industry Alignment
- [ ] Separate lifecycle from functional testing (industry standard)
- [ ] Version-controlled baselines (industry standard)
- [ ] Trend tracking with regression detection (industry standard)
- [ ] Domain-adapted test levels (not generic categories)
- [ ] CI-ready pattern (manual trigger now, automatable later)

---

## 📝 Next Steps

1. **Human Review**: Approve this concept document
2. **Framework Impact Analysis**: Read each affected task/artifact in full, document exact changes needed
3. **Create Temporary State Tracking File**: `New-TempTaskState.ps1` for multi-session tracking
4. **Begin Session 1**: Guide + Tracking Infrastructure + Results DB

---

## 📋 Human Review

**Review Date**: 2026-04-08
**Decision**: PENDING
**Comments**:

---

*This concept document was created using the Framework Extension Concept Template (PF-TEM-032) as part of the Framework Extension Task (PF-TSK-026).*
