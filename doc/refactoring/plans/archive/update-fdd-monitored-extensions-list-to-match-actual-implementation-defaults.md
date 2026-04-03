---
id: PD-REF-152
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-02
updated: 2026-04-02
mode: lightweight
priority: Medium
target_area: FDD Core Architecture
refactoring_scope: Update FDD monitored_extensions list to match actual implementation defaults
---

# Lightweight Refactoring Plan: Update FDD monitored_extensions list to match actual implementation defaults

- **Target Area**: FDD Core Architecture
- **Priority**: Medium
- **Created**: 2026-04-02
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD156 — FDD monitored_extensions list outdated (6 vs ~32 actual)

**Scope**: FDD PD-FDD-022 business rule 0.1.1-BR-3 hard-codes 6 extensions (`.md`, `.yaml`, `.yml`, `.json`, `.py`, `.dart`) but the actual default set in `linkwatcher/config/defaults.py` contains ~32 extensions across 6 categories (docs, web dev, images, documents, source code, scripts/config, media). The FDD should reference the configurable nature and current default categories rather than listing a stale subset.

**Dims**: DA (Documentation Alignment)

**Changes Made**:
<!-- Fill in after implementation -->
- [x] Update 0.1.1-BR-3 in fdd-0-1-1-core-architecture.md to reflect actual extension categories and configurable nature

**Test Baseline**: N/A — documentation-only change, no code modified
**Test Result**: N/A

**Documentation & State Updates**:
- [ ] Feature implementation state file (0.1.1) updated, or N/A — _N/A: doc-only change to FDD, no code component changed_
- [ ] TDD (0.1.1) updated, or N/A — _N/A: TDD documents architecture, not the specific extension list in business rules_
- [ ] Test spec (0.1.1) updated, or N/A — _N/A: no behavior change, doc-only fix_
- [x] FDD (0.1.1) updated — this IS the FDD fix
- [ ] ADR updated, or N/A — _N/A: no architectural decision affected_
- [ ] Validation tracking updated, or N/A — _N/A: this is a doc fix from validation findings, not a feature change_
- [x] Technical Debt Tracking: TD156 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD156 | Complete | None | FDD 0.1.1-BR-3 |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)

