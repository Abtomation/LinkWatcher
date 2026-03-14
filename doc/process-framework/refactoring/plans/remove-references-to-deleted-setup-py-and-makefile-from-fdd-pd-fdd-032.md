---
id: PF-REF-063
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-13
updated: 2026-03-13
priority: Medium
target_area: FDD 5.1.1 CI/CD Development Tooling
refactoring_scope: Remove references to deleted setup.py and Makefile from FDD PD-FDD-032
mode: lightweight
---

# Lightweight Refactoring Plan: Remove references to deleted setup.py and Makefile from FDD PD-FDD-032

- **Target Area**: FDD 5.1.1 CI/CD Development Tooling
- **Priority**: Medium
- **Created**: 2026-03-13
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (≤15 min effort, single file, no architectural impact)

## Item 1: TD051 — Remove deleted setup.py and Makefile references from FDD PD-FDD-032

**Scope**: FDD PD-FDD-032 (5.1.1 CI/CD & Development Tooling) references `setup.py` and `Makefile` throughout subsystems D, E, F, and G. Both files were deleted (TD039 removed Makefile, TD040 removed setup.py). The FDD must be updated to reflect `pyproject.toml` as sole package config and `dev.bat` as sole dev script.

**Specific changes planned**:
- 5.1.4-FR-2: Remove `setup.py` from coverage omit list
- 5.1.5-FR-3: Remove Makefile from pre-commit install references
- 5.1.5-AC-2: Remove Makefile from acceptance criteria
- 5.1.6-FR-1: Remove dual config description, pyproject.toml only
- 5.1.6-FR-5: Remove Makefile targets reference
- 5.1.6-BR-1: Remove setup.py legacy note
- 5.1.7-FR-1: Remove Makefile as co-equal script
- 5.1.7-FR-3: Remove Makefile help target
- 5.1.7-FR-4: Remove Makefile release-check target
- 5.1.7-BR-1: Update to dev.bat only
- 5.1.7-AC-2: Remove make help reference
- 5.1.7-AC-3: Remove make release-check reference

**Changes Made**:
- [x] All setup.py references removed or updated (5.1.4-FR-2, 5.1.6-FR-1, 5.1.6-BR-1)
- [x] All Makefile references removed or updated (5.1.5-FR-3, 5.1.5-AC-2, 5.1.6-FR-5, 5.1.7-FR-1, 5.1.7-FR-3/FR-4 removed, 5.1.7-BR-1, 5.1.7-AC-2/AC-3 removed)
- [x] Subsystem descriptions updated to reflect current tooling (dev.bat only, pyproject.toml only)
- [x] FR numbering consolidated in Subsystem G (FR-3/FR-4/FR-5 collapsed to FR-3 after removing Makefile-only items)

**Test Baseline**: N/A — documentation-only change, no code affected
**Test Result**: N/A

**Documentation & State Updates**:
- [x] Feature implementation state file (5.1.1) updated, or N/A — _N/A: no consolidated 5.1.1 state file exists (only archived sub-feature files which are read-only)_
- [x] TDD (5.1.1) updated, or N/A — _N/A: grepped PD-TDD-031 — no setup.py/Makefile references found_
- [x] Test spec (5.1.1) updated, or N/A — _N/A: PF-TSP-043 has stale setup.py/Makefile references but these are out of TD051 scope (FDD only). Noted as discovery below._
- [x] FDD (5.1.1) updated — _this IS the FDD change (PD-FDD-032)_
- [x] ADR updated, or N/A — _N/A: grepped ADR directory — no setup.py/Makefile references found_
- [x] Foundational validation tracking updated — _updated TD051 row from "Open" to "Resolved"_
- [x] Technical Debt Tracking: TD051 marked resolved

**Bugs Discovered**: None

**Discovery**: Test spec PF-TSP-043 (5.1.1) still references setup.py and Makefile in 4 locations (lines 30, 91, 131, 133). Not tracked as tech debt — out of TD051 scope. Recommend adding as new TD item or addressing in TD052 batch.

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD051 | Complete | None | FDD PD-FDD-032, foundational-validation-tracking.md |

## Related Documentation
- [Technical Debt Tracking](/doc/process-framework/state-tracking/permanent/technical-debt-tracking.md)
