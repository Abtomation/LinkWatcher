---
id: PF-STA-087
type: Process Framework
category: State File
version: 1.0
created: 2026-04-13
updated: 2026-04-13
change_name: test-audit-multi-type-extension
---

# Structure Change State: Test Audit Multi-Type Extension

> **⚠️ TEMPORARY FILE**: Move to `process-framework-local/state-tracking/temporary/old` after all sessions complete.

## Overview
- **Change Name**: Test Audit Multi-Type Extension
- **Concept Document**: [PF-PRO-022](/process-framework-local/proposals/old/test-audit-multi-type-extension.md)
- **Source IMPs**: PF-IMP-495 (multi-type audit), PF-IMP-496 (minor fix authority), PF-IMP-498 (scalability guidance)
- **Task**: PF-TSK-026 (Framework Extension)
- **Scope**: Extend PF-TSK-030 to audit performance and E2E tests with type-specific criteria, templates, and tracking integration

## Progress Overview

| Session | Focus | Status | Date |
|---------|-------|--------|------|
| 0 | Concept + Impact Analysis + Planning | ✅ Completed | 2026-04-13 |
| 1 | Core task definition + templates | ✅ Completed | 2026-04-13 |
| 2 | Script modifications | ✅ Completed | 2026-04-13 |
| 3 | Upstream/downstream task integration | ✅ Completed | 2026-04-13 |
| 4 | Framework integration + docs + finalization | ✅ Completed | 2026-04-13 |

## Affected Components

### Task Definitions (6)

| Task | ID | Change | Session | Status |
|------|-----|--------|---------|--------|
| Test Audit | PF-TSK-030 | Add test type routing, type-specific criteria, minor fix authority, scalability guidance, reframe coverage as regression check | 1 | ✅ |
| Performance Test Creation | PF-TSK-084 | Add PF-TSK-030 to Next Tasks | 3 | ✅ |
| Performance Baseline Capture | PF-TSK-085 | Add hard prerequisite: `🔍 Audit Approved` for `📋 Created` tests | 3 | ✅ |
| E2E Test Case Creation | PF-TSK-069 | Add PF-TSK-030 to Next Tasks | 3 | ✅ |
| E2E Test Execution | PF-TSK-070 | Add hard prerequisite: `🔍 Audit Approved` for `📋 Case Created` cases | 3 | ✅ |
| Performance & E2E Test Scoping | PF-TSK-086 | Update lifecycle description to show audit gate | 3 | ✅ |

### Scripts (8)

| Script | Change | Session | Status |
|--------|--------|---------|--------|
| New-TestAuditReport.ps1 | Add `-TestType` param, template routing, tracking file selection | 2 | ✅ |
| Update-TestFileAuditState.ps1 | Add `-TestType` param, multi-tracking-file support | 2 | ✅ |
| New-AuditTracking.ps1 | Add `-TestType` param, inventory from correct tracking file | 2 | ✅ |
| Validate-AuditReport.ps1 | Type-specific section validation (+ auto-detection) | 2 | ✅ |
| New-PerformanceTestEntry.ps1 | Add Audit Status + Audit Report columns to generated rows | 2 | ✅ |
| New-E2EAcceptanceTestCase.ps1 | Add Audit Status + Audit Report columns to generated rows | 2 | ✅ |
| Update-TestExecutionStatus.ps1 | Preserve audit columns when writing (Notes index 8→10) | 2 | ✅ |
| Update-PerformanceTracking.ps1 | Fix SpecRef column index 9→11 | 2 | ✅ |

### Templates (2 new)

| Template | Purpose | Session | Status |
|----------|---------|---------|--------|
| Performance Test Audit Report Template (PF-TEM-073) | 4-criteria evaluation for perf tests | 1 | ✅ |
| E2E Test Audit Report Template (PF-TEM-074) | 5-criteria evaluation for E2E tests | 1 | ✅ |

### Tracking File Schema Changes (2)

| File | Change | Session | Status |
|------|--------|---------|--------|
| performance-test-tracking.md | Add Audit Status + Audit Report columns to all 4 level tables + lifecycle note | 2 | ✅ |
| e2e-test-tracking.md | Add Audit Status + Audit Report columns to Test Case Inventory (43 rows) | 2 | ✅ |

### Documentation (11)

| Document | Change | Session | Status |
|----------|--------|---------|--------|
| Test Audit Usage Guide (PF-GDE-041) | Add perf/E2E criteria sections, minor fix authority, scalability guidance | 1 | ✅ |
| ai-tasks.md | Insert audit gate in perf/E2E workflow paths | 4 | ✅ |
| task-transition-registry.md | Add perf/E2E audit transition paths + new PF-TSK-084/085 sections | 4 | ✅ |
| process-framework-task-registry.md | Update PF-TSK-030/084/085/069/070 entries | 4 | ✅ |
| performance-testing-guide.md | Update lifecycle: ⬜→📋→🔍→✅ | 4 | ✅ |
| performance-and-e2e-test-scoping-guide.md | Reference audit gate in post-scoping lifecycle | 4 | ✅ |
| definition-of-done.md | Add audit approval for perf/E2E tests | 4 | ✅ |
| PF-documentation-map.md | Add new templates | 4 | ✅ |
| TE-documentation-map.md | Add perf/E2E audit categories | 4 | ✅ |
| Test Audit Context Map | Add perf/E2E components | 3 | ✅ |
| process-improvement-tracking.md | Close PF-IMP-495/496/498; update PF-IMP-497 notes | 4 | ✅ |

### Directories (2 new)

| Directory | Session | Status |
|-----------|---------|--------|
| test/audits/performance/ | 1 | ✅ |
| test/audits/e2e/ | 1 | ✅ |

## Session Plans

### Session 1: Core Task Definition + Templates
**Priority**: HIGH — foundation for all other changes

1. Modify PF-TSK-030 task definition:
   - Add test type routing step (new Step 0.5 or modify Step 1)
   - Add Performance Test Criteria section (4 criteria)
   - Add E2E Test Criteria section (5 criteria)
   - Add Minor Fix Authority section (≤15 min scope, allowed fix types)
   - Add Scalability Guidance section (risk-based sampling, batch patterns, re-audit triggers)
   - Reframe Step 4 coverage check as regression detection
   - Update script commands to show `-TestType` parameter
2. Create Performance Test Audit Report Template (using existing PF-TEM-023 as pattern)
3. Create E2E Test Audit Report Template (using existing PF-TEM-023 as pattern)
4. Create test/audits/performance/ and test/audits/e2e/ directories
5. Update Test Audit Usage Guide (PF-GDE-041) with type-specific sections

### Session 2: Script Modifications
**Priority**: HIGH — enables the workflow

1. Extend New-TestAuditReport.ps1: `-TestType` param, template routing, tracking file selection
2. Extend Update-TestFileAuditState.ps1: `-TestType` param, multi-tracking-file write
3. Extend New-AuditTracking.ps1: `-TestType` param, inventory source routing
4. Extend Validate-AuditReport.ps1: type-specific section validation
5. Add audit columns to performance-test-tracking.md (all 4 level tables)
6. Add audit columns to e2e-test-tracking.md (Test Case Inventory)
7. Update New-PerformanceTestEntry.ps1: include empty audit columns in row
8. Update New-E2EAcceptanceTestCase.ps1: include empty audit columns in row
9. Update Update-TestExecutionStatus.ps1: preserve audit columns
10. Update Validate-StateTracking.ps1: surface parsers for new columns

### Session 3: Upstream/Downstream Task Integration
**Priority**: HIGH — wires audit gate into lifecycles

1. Update PF-TSK-084: Next Tasks → add PF-TSK-030 (performance context)
2. Update PF-TSK-085: add hard prerequisite `🔍 Audit Approved` for `📋 Created`; exempt `⚠️ Stale`
3. Update PF-TSK-069: Next Tasks → add PF-TSK-030 (E2E context)
4. Update PF-TSK-070: add hard prerequisite `🔍 Audit Approved` for `📋 Case Created`; exempt `🔄 Needs Re-execution`
5. Update PF-TSK-086: lifecycle description with audit gate
6. Update Test Audit Context Map: add perf/E2E tracking files, templates, criteria

### Session 4: Framework Integration + Docs + Finalization
**Priority**: MEDIUM — completes the integration

1. Update ai-tasks.md workflow diagrams (Performance Testing + E2E Testing paths)
2. Update task-transition-guide.md (perf/E2E audit transition paths)
3. Update process-framework-task-registry.md (PF-TSK-030/084/085/069/070 entries)
4. Update performance-testing-guide.md (lifecycle)
5. Update performance-and-e2e-test-scoping-guide.md (audit reference)
6. Update definition-of-done.md (quality gates)
7. Update PF-documentation-map.md + TE-documentation-map.md
8. Update Validate-StateTracking.ps1 if not done in Session 2
9. Close PF-IMP-495/496/498 in process-improvement-tracking.md; update PF-IMP-497 notes
10. Archive concept document → proposals/old/
11. Move this state file → state-tracking/temporary/old/
12. Feedback form

## Key Decisions

| Decision | Rationale | Date |
|----------|-----------|------|
| Single task (PF-TSK-030) parameterized, not separate tasks | Follows validation dimension pattern; avoids task proliferation | 2026-04-13 |
| Hard prerequisite for audit gate | Audit approval mandatory before baseline/execution — no bypass | 2026-04-13 |
| Stale/re-execution exempt from audit gate | Already audited once; gate only for freshly created tests | 2026-04-13 |
| PF-IMP-497 excluded | Coverage check serves temporal regression detection purpose distinct from PF-TSK-053/005 | 2026-04-13 |
| 4 perf criteria, 5 E2E criteria | Approved by human partner 2026-04-13 | 2026-04-13 |
| `-TestType` defaults to Automated | Backward compatibility — existing workflow unaffected | 2026-04-13 |

## Session Log

### Session 0: 2026-04-13
**Focus**: Concept development + impact analysis + planning
**Completed**:
- Pre-concept analysis (a-e): task transitions, trigger/output chains, precedents, abstraction model, lifecycle trace, scalability
- Framework Extension Concept document (PF-PRO-022) created and customized
- Human review: criteria approved, hard prerequisite approved, PF-IMP-497 excluded
- Impact analysis: 27 artifacts across 4 categories mapped with specific changes
- State tracking file (PF-STA-087) created with 4-session implementation roadmap
- Human approval for Phase 2 obtained

**Issues/Blockers**: None

**Next Session Plan**: Session 1 — Core task definition + templates

### Session 1: 2026-04-13
**Focus**: Core task definition + templates
**Completed**:
- PF-TSK-030 v2.0: Added test type determination table, type-specific criteria (4 perf + 5 E2E), minor fix authority section, scalability guidance, coverage regression reframing, multi-type script commands, type-specific Next Tasks, updated State Tracking and Completion Checklist
- PF-TEM-073: Performance Test Audit Report Template (4 criteria: Measurement Methodology, Tolerance Appropriateness, Baseline Readiness, Regression Detection Config)
- PF-TEM-074: E2E Test Audit Report Template (5 criteria: Fixture Correctness, Scenario Completeness, Expected Outcome Accuracy, Reproducibility, Precondition Coverage)
- Created test/audits/performance/ and test/audits/e2e/ directories
- PF-GDE-041 v2.0: Added Test Type Selection, Minor Fix Authority, Scalability Guidance sections; Performance Test Criteria (4 criteria) and E2E Test Criteria (5 criteria) sections with assessment levels

**Issues/Blockers**: None

**Next Session Plan**: Session 2 — Script modifications (8 scripts + 2 tracking file schema changes)

### Session 2: 2026-04-13
**Focus**: Script modifications + tracking file schema changes
**Completed**:
- performance-test-tracking.md: Added Audit Status + Audit Report columns to all 4 level tables (16 rows), updated lifecycle description
- e2e-test-tracking.md: Added Audit Status + Audit Report columns to Test Case Inventory (43 rows)
- New-PerformanceTestEntry.ps1: Row construction updated to include empty audit columns (12-column format)
- New-E2EAcceptanceTestCase.ps1: Both case row and group row updated to include empty audit columns (11-column format)
- New-TestAuditReport.ps1 v2.0: Added -TestType param (Automated/Performance/E2E, default Automated), template routing (3 templates), tracking file routing (test-tracking.md vs performance-test-tracking.md vs e2e-test-tracking.md), Audit Status + Report column updates for perf/E2E, -Lightweight validation (Automated only)
- Update-TestFileAuditState.ps1 v3.0: Added -TestType param, early-return branch for Performance/E2E (updates Audit Status + Audit Report columns directly), Automated path unchanged
- New-AuditTracking.ps1: Added -TestType param, inventory source routing (3 tracking files), type-specific auditable status filters, type-suffixed filenames (audit-tracking-performance-N.md, audit-tracking-e2e-N.md)
- Validate-AuditReport.ps1: Auto-detection of test type from content + optional -TestType param, type-specific criteria validation (6 Automated / 4 Performance / 5 E2E)
- Update-TestExecutionStatus.ps1: Notes column index 8→10, count check 9→11, column comment updated
- Update-PerformanceTracking.ps1 (bonus discovery): SpecRef column index 9→11, column map comment updated
- Validate-StateTracking.ps1: No changes needed — no existing surfaces parse performance/e2e tracking file column structure

**Issues/Blockers**: None. Discovered Update-PerformanceTracking.ps1 also needed column index update (not in original plan).

**Next Session Plan**: Session 3 — Upstream/downstream task integration (6 task definitions)

### Session 3: 2026-04-13
**Focus**: Upstream/downstream task integration
**Completed**:
- PF-TSK-084 v1.1: Added Test Audit (PF-TSK-030 with `-TestType Performance`) as first Next Task before Baseline Capture, with `🔍 Audit Approved` requirement note
- PF-TSK-085 v1.1: Added Step 2 hard prerequisite — `🔍 Audit Approved` required for `📋 Created` entries before baseline capture; `⚠️ Stale` and `✅ Baselined` exempt (already audited); renumbered steps 2-11 → 3-12; added Test Audit to Related Resources
- PF-TSK-069 v1.2: Added Test Audit (PF-TSK-030 with `-TestType E2E`) as first Next Task before E2E Test Execution, with `🔍 Audit Approved` requirement note
- PF-TSK-070 v1.2: Added Step 2 hard prerequisite — `🔍 Audit Approved` required for `📋 Case Created` entries before execution; `🔄 Needs Re-execution` exempt (already audited); renumbered steps 2-10 → 3-11; added Test Audit to Related Resources
- PF-TSK-086 v1.1: Updated Next Tasks with full downstream lifecycle annotations (⬜ Specified → 📋 Created → 🔍 Audit Approved → ✅ Baselined for perf; 📋 Case Created → 🔍 Audit Approved → ✅ Passed for E2E); added audit gate callout note
- Test Audit Context Map v2.0: Complete rewrite — added Test Type Determination routing node, Performance (4) and E2E (5) criteria nodes, three type-specific audit report nodes, three tracking file nodes; updated Essential Components with type-specific descriptions; updated Key Relationships with downstream gate relationship; updated Implementation section with type-aware flow; expanded Related Documentation with all templates, scripts, and tracking files

**Issues/Blockers**: None

**Next Session Plan**: Session 4 — Framework integration + docs + finalization (11 documentation items + feedback form)

### Session 4: 2026-04-13
**Focus**: Framework integration + docs + finalization
**Completed**:
- ai-tasks.md: Inserted audit gate in E2E Testing and Performance Testing workflow paths; added audit gate callout notes with exemption details
- task-transition-registry.md: Updated "FROM Test Audit" to multi-type routing (Automated/Performance/E2E next steps); updated "FROM E2E Test Case Creation" to route through audit; added new "FROM Performance Test Creation" and "FROM Performance Baseline Capture" sections; updated "FROM Performance & E2E Test Scoping" decision tree with audit gate
- process-framework-task-registry.md: Updated PF-TSK-030 (multi-type scripts, output directories, file operations for 3 tracking files, type-specific KEY IMPACTS); PF-TSK-084 (next step + TRIGGER & OUTPUT with audit gate); PF-TSK-085 (audit prerequisite in dependencies + trigger); PF-TSK-069 (next step + output with audit gate); PF-TSK-070 (audit prerequisite in dependencies + trigger)
- performance-testing-guide.md: Updated lifecycle to include 🔍 Audit Approved step with audit gate callout
- performance-and-e2e-test-scoping-guide.md: Added Post-Scoping Lifecycle section showing full downstream lifecycle for both perf and E2E; added Test Audit to Related Resources
- definition-of-done.md: Added 2 new quality gate checkboxes for perf test audit and E2E test audit approval
- PF-documentation-map.md: Added Performance Test Audit Report Template (PF-TEM-073) and E2E Test Audit Report Template (PF-TEM-074)
- TE-documentation-map.md: Added audits/performance/ and audits/e2e/ sections with criteria descriptions
- process-improvement-tracking.md: Closed PF-IMP-495 (HIGH), PF-IMP-496 (HIGH), PF-IMP-498 (LOW) via automation script; updated PF-IMP-497 notes with exclusion rationale

**Issues/Blockers**: None

**All sessions complete. Extension fully integrated.**
