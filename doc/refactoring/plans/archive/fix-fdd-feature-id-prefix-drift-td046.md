---
id: PD-REF-058
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-04
updated: 2026-03-04
mode: lightweight
priority: Medium
refactoring_scope: Fix FDD feature ID prefix drift (TD046)
target_area: FDD Documents
---

# Lightweight Refactoring Plan: Fix FDD feature ID prefix drift (TD046)

- **Target Area**: FDD Documents
- **Priority**: Medium
- **Created**: 2026-03-04
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (≤15 min effort, single file, no architectural impact)

## Item 1: TD046 — Fix FDD feature ID prefix drift in PD-FDD-023 and PD-FDD-024

**Scope**: PD-FDD-023 (In-Memory Database) uses `0.1.3-` prefix throughout but feature was renumbered to 0.1.2 during consolidation. PD-FDD-024 (File System Monitoring) uses `1.1.2-` prefix throughout but feature is 1.1.1. PD-FDD-024 also states "2-second buffer" for move detection but actual code uses 10-second delay. All are stale references from pre-consolidation era.

**Changes Made**:
- [x] PD-FDD-023: Replace Feature ID `0.1.3` → `0.1.2` in Feature Overview
- [x] PD-FDD-023: Replace all `0.1.3-` requirement prefixes → `0.1.2-` (FR-1–7, UI-1–4, BR-1–5, AC-1–7, EC-1–6)
- [x] PD-FDD-024: Replace Feature ID `1.1.2` → `1.1.1` in Feature Overview
- [x] PD-FDD-024: Replace all `1.1.2-` requirement prefixes → `1.1.1-` (FR-1–7, UI-1–5, BR-1–6, AC-1–7, EC-1–7)
- [x] PD-FDD-024: Fix 3 "2-second" timer references → "10-second" (matches move_detector.py delay=10.0)

**Test Baseline**: N/A — documentation-only changes, no code modified
**Test Result**: N/A

**Documentation & State Updates**:
- [x] Feature implementation state file: N/A — grepped state files for `0.1.3-FR`, `1.1.2-FR` etc.; no matches found
- [x] TDD: N/A — grepped TDD files for old prefixes; no matches found
- [x] Test spec: N/A — grepped test specs for old prefixes; no matches found
- [x] FDD updated — this IS the FDD fix (PD-FDD-023 and PD-FDD-024 are the targets)
- [x] ADR: N/A — grepped ADR directory for old prefixes; no matches found
- [x] Foundational validation tracking: N/A — grepped tracking file for old prefixes; no matches found
- [x] Technical Debt Tracking: TD046 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD046 | Complete | None | PD-FDD-023, PD-FDD-024 |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
