---
id: PF-REF-068
type: Document
category: General
version: 1.0
created: 2026-03-13
updated: 2026-03-13
priority: Medium
target_area: TDD 5.1.1 CI/CD Development Tooling
refactoring_scope: Expand TDD PD-TDD-031 to cover all 7 FDD subsystems
---

# Refactoring Plan: Expand TDD PD-TDD-031 to cover all 7 FDD subsystems

## Overview
- **Target Area**: TDD 5.1.1 CI/CD Development Tooling
- **Priority**: Medium
- **Created**: 2026-03-13
- **Author**: AI Agent & Human Partner
- **Status**: Complete

## Refactoring Scope

TD055: TDD PD-TDD-031 (5.1.1 CI/CD & Development Tooling) only covers 2 of 7 FDD subsystems. The FDD (PD-FDD-032) defines subsystems A through G, but the TDD only documents A (CI Pipeline) and B (Test Automation).

### Current Issues

- TDD PD-TDD-031 missing Subsystem C: Code Quality Checks (flake8, black, isort, mypy configuration and CI integration)
- TDD PD-TDD-031 missing Subsystem D: Coverage Reporting (pytest-cov configuration, Codecov integration, exclusion patterns)
- TDD PD-TDD-031 missing Subsystem E: Pre-commit Hooks (.pre-commit-config.yaml structure, hook repos, local pytest-quick hook)
- TDD PD-TDD-031 missing Subsystem F: Package Building (pyproject.toml build system, CI build job, deployment scripts)
- TDD PD-TDD-031 missing Subsystem G: Windows Dev Scripts (dev.bat command routing, target implementations)

### Scope Discovery

- **Original Tech Debt Description**: TD055 — TDD PD-TDD-031 only covers 2 of 7 FDD subsystems — missing pre-commit hooks, dev.bat, dependency management, code quality, release/versioning
- **Actual Scope Findings**: Confirmed. TDD has 2 subsections (CI Pipeline, Test Automation). FDD has 7 subsystems (A-G). The 5 missing subsystems are all fully implemented in source code and documented in the FDD but have no corresponding TDD technical design documentation.
- **Scope Delta**: None — scope matches original description exactly.

### Refactoring Goals

- Add 5 new TDD subsections (C through G) matching FDD subsystem structure
- Follow existing TDD Tier 2 pattern: technical overview, implementation details, key technical decisions
- Update Dependencies table to reference components from new subsystems
- Ensure accuracy by deriving content from actual source files (ci.yml, pyproject.toml, .pre-commit-config.yaml, dev.bat)

## Current State Analysis

### Code Quality Metrics (Baseline)

- **TDD Subsystem Coverage**: 2 of 7 FDD subsystems documented (29%)
- **TDD Line Count**: ~136 lines of technical content
- **Documentation Completeness**: Partial — CI pipeline and test automation well-documented, 5 subsystems entirely missing

### Affected Components

- `doc/product-docs/technical/architecture/design-docs/tdd/tdd-5-1-1-cicd-development-tooling-t2.md` — the TDD being expanded

### Source Files (read-only reference)

- `.github/workflows/ci.yml` — CI quality and security job definitions
- `pyproject.toml` — tool configs ([tool.black], [tool.isort], [tool.mypy], [tool.coverage.*], [build-system])
- `.pre-commit-config.yaml` — pre-commit hook definitions
- `dev.bat` — Windows development command router

### Dependencies and Impact

- **Internal Dependencies**: Feature state file PF-FEA-054 references TDD. Documentation map links to TDD.
- **External Dependencies**: None
- **Risk Assessment**: Low — documentation-only change, no code modifications

## Refactoring Strategy

### Approach

Add 5 new subsection blocks to the TDD, inserted between the existing "Test Automation" subsection and the "Dependencies (Consolidated)" section. Each subsection follows the established Tier 2 TDD pattern used by the existing subsections: technical overview paragraph, implementation detail tables/lists, and "Key Technical Decisions" explaining design rationale.

### Implementation Plan

1. **Phase 1**: Add Subsystem C (Code Quality Checks)
   - Document CI quality job structure (flake8, black, isort, mypy)
   - Document pyproject.toml tool configuration centralization
   - Document key decision: soft failure mode for quality checks

2. **Phase 2**: Add Subsystem D (Coverage Reporting)
   - Document coverage toolchain (pytest-cov → coverage.py → Codecov)
   - Document pyproject.toml coverage configuration and exclusion patterns
   - Document key decision: single Python version for Codecov upload

3. **Phase 3**: Add Subsystem E (Pre-commit Hooks)
   - Document .pre-commit-config.yaml hook repository structure
   - Document local pytest-quick hook configuration
   - Document key decision: CI-mirroring pre-commit strategy

4. **Phase 4**: Add Subsystem F (Package Building)
   - Document pyproject.toml build system and metadata
   - Document CI build job gating and artifact creation
   - Document key decision: PEP 621 sole configuration

5. **Phase 5**: Add Subsystem G (Windows Dev Scripts)
   - Document dev.bat command routing architecture
   - Document command-to-tool delegation pattern
   - Document key decision: Windows-native batch file as canonical interface

6. **Phase 6**: Update Dependencies table
   - Add entries for new subsystem components

## Testing Strategy

N/A — documentation-only change. No code is modified, so no test execution is required. Validation will consist of verifying the TDD content matches the actual source files.

## Success Criteria

### Quality Improvements

- **TDD Subsystem Coverage**: Target 7 of 7 FDD subsystems documented (100%, up from 29%)
- **Technical Debt**: TD055 resolved

### Completion Requirements

- [ ] All 5 missing subsections added to TDD
- [ ] Each subsection accurately reflects actual source code
- [ ] Dependencies table updated with new component references
- [ ] No functional changes to any code

## Implementation Tracking

### Progress Log
<!-- Track progress during implementation -->
| Date | Phase | Completed Work | Issues Encountered | Next Steps |
|------|-------|----------------|-------------------|------------|
| 2026-03-13 | Phase 1-6 | Added 5 subsections (C-G) and updated Dependencies table | None | Validate and finalize |

### Metrics Tracking

| Metric | Baseline | Final | Target | Status |
|--------|----------|-------|--------|--------|
| TDD Subsystem Coverage | 2/7 (29%) | 7/7 (100%) | 7/7 (100%) | ✅ Met |
| TDD Content Lines | ~136 | ~402 | Full coverage | ✅ Met |
| Dependencies Table Entries | 11 | 16 | Complete | ✅ Met |

## Results and Lessons Learned

### Final Metrics

- **TDD Subsystem Coverage**: 7/7 (100%, up from 29%)
- **TDD Content**: ~266 lines added across 5 subsections
- **Dependencies Table**: 16 entries (up from 11), with accurate subsystem cross-references
- **Technical Debt**: TD055 resolved

### Achievements

- Added 5 complete TDD subsections (C: Code Quality, D: Coverage Reporting, E: Pre-commit Hooks, F: Package Building, G: Windows Dev Scripts)
- Each subsection follows the established Tier 2 pattern with implementation detail tables and Key Technical Decisions
- Updated consolidation scope note and technical overview to reflect full 7-subsystem coverage
- Dependencies table expanded with 5 new components and accurate subsystem mappings

### Bug Discovery Checklist

- Logic errors: N/A (documentation only)
- Hidden dependencies: N/A (documentation only)
- Performance issues: N/A (documentation only)
- Error handling gaps: N/A (documentation only)
- Integration issues: N/A (documentation only)
- Data handling bugs: N/A (documentation only)
- Concurrency issues: N/A (documentation only)
- Resource management: N/A (documentation only)

No bugs discovered — this was a documentation-only change.

### Remaining Technical Debt

None — TD055 fully resolved.

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
- [Code Quality Standards](/doc/process-framework/guides/03-testing/code-quality-standards.md)
- [Testing Guidelines](/doc/process-framework/guides/03-testing/testing-guidelines.md)
