---
id: PF-TEM-049
type: Process Framework
category: Template
version: 1.3
created: 2026-02-17
updated: 2026-04-05
creates_document_prefix: PF-STA
creates_document_version: 1.0
description: Template for retrospective master state tracking during onboarding
creates_document_type: Process Framework
usage_context: Process Framework - Onboarding State Tracking
creates_document_category: State Tracking
template_for: Retrospective Master State
---

# Retrospective Documentation Master State - [Project Name]

**Project**: [Project Name]
**Started**: [YYYY-MM-DD]
**Status**: [DISCOVERY | ANALYSIS | ASSESSMENT_AND_DOCUMENTATION | FINALIZATION | COMPLETE]
**Total Features**: [N]
**Task References**:
- [Codebase Feature Discovery (PF-TSK-064)](../../tasks/00-setup/codebase-feature-discovery.md)
- [Codebase Feature Analysis (PF-TSK-065)](../../tasks/00-setup/codebase-feature-analysis.md)
- [Retrospective Documentation Creation (PF-TSK-066)](../../tasks/00-setup/retrospective-documentation-creation.md)

---

## Phase Completion Status

- [ ] **Phase 1: Feature Discovery & Code Assignment** (Target: 100% file coverage)
- [ ] **Phase 2: Analysis** (Target: All features analyzed)
- [ ] **Phase 3: Tier Assessment & Documentation Creation** (Target: All features assessed and documented)
- [ ] **Phase 4: Finalization** (Target: All links, tracking complete)

---

## Coverage Metrics

### Codebase File Coverage

- **Total Project Source Files**: [N] (excluding doc/, .git/, __pycache__/, node_modules/, etc.)
- **Files Assigned to Features**: [M]
- **Unassigned Files**: [N-M]
- **Coverage**: [M/N * 100]%

### Feature Progress Overview

| Phase | Not Started | In Progress | Complete | Total |
|-------|-------------|-------------|----------|-------|
| Phase 1: Discovery & Assignment | [N] | [N] | [N] | [N] |
| Phase 2: Analysis | [N] | [N] | [N] | [N] |
| Phase 3: Assessment & Documentation | [N] | [N] | [N] | [N] |

### Documentation Requirements Summary

| Tier | Feature Count | Impl State | FDD Needed | TDD Needed | Test Spec | ADR | Total Docs Needed | Docs Created |
|------|---------------|------------|------------|------------|-----------|-----|-------------------|--------------|
| Foundation | [N] | 0/[N] | 0/[N] | 0/[N] | N/A | 0/[N] | [N] | 0 |
| Tier 3 | [N] | 0/[N] | 0/[N] | 0/[N] | 0/[N] | N/A | [N] | 0 |
| Tier 2 | [N] | 0/[N] | 0/[N] | 0/[N] | N/A | N/A | [N] | 0 |
| Tier 1 | [N] | 0/[N] | N/A | N/A | N/A | N/A | 0 | 0 |
| **Total** | **[N]** | **0/[N]** | | | | | **[N]** | **0** |

---

## Feature Inventory

> **Instructions**: Create one table per feature category. Mark each column with ⬜ (not started), 🟡 (in progress), or ✅ (complete). Use N/A where a document is not required for the feature's tier.

### [Category 0: Category Name]

| Feature ID | Feature Name | Tier | Impl State | Analyzed | Assessed | FDD | TDD | Test Spec | ADR | Notes |
|------------|-------------|------|------------|----------|----------|-----|-----|-----------|-----|-------|
| [0.1.1] | [Feature Name] | [T?] | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | N/A | ⬜ | |
| [0.1.2] | [Feature Name] | [T?] | ⬜ | ⬜ | ⬜ | N/A | N/A | N/A | N/A | |

### [Category 1: Category Name]

| Feature ID | Feature Name | Tier | Impl State | Analyzed | Assessed | FDD | TDD | Test Spec | ADR | Notes |
|------------|-------------|------|------------|----------|----------|-----|-----|-----------|-----|-------|
| [1.1.1] | [Feature Name] | [T?] | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | N/A | N/A | |

> **Add more category tables as needed for the project's feature structure.**

---

## Unassigned Files

> **Target**: All files should be marked ✅ in the Status column when Phase 1 is complete. Rows are never removed — the full file list is preserved as a permanent record.
>
> **Status**: ⬜ = not yet processed | ✅ = deeply analyzed and written to at least one feature's Code Inventory

| File Path | Notes | Candidate Feature | Status |
|-----------|-------|-------------------|--------|
| [path/to/file.ext] | [note about what this file does] | [suggested feature ID] | ⬜ |

---

## Existing Documentation Inventory

> Cross-cutting index of all pre-existing project documentation audited during Phase 1 (PF-TSK-064 step 3b). Feature-level details are in each feature's Section 4 "Existing Project Documentation" table.
>
> For new projects: _No pre-existing project documentation — project started with process framework._
>
> **Consumption Status** (Phase 4 Step 17 — Gap Analysis):
> - **Fully Consumed**: All valuable content captured in framework docs during Phase 3
> - **Partially Consumed**: Some content extracted but sections remain uncaptured — identify gaps
> - **Not Consumed**: Not used as source material — evaluate if content is valuable

| Document | Location | Type | Mapped Features | Confirmed (Phase 2) | Captured By | Consumption Status |
| -------- | -------- | ---- | --------------- | -------------------- | ----------- | ------------------ |
| [name] | [path] | [Architecture Overview / User Guide / Test Plan / CI/CD / Troubleshooting / Developer Guide / Configuration / Changelog / Other] | [Feature IDs] | [⬜ / ✅] | [Framework doc IDs that consumed this content, e.g., PD-TDD-003, PD-FDD-001] | [⬜ / Fully Consumed / Partially Consumed / Not Consumed] |

---

## Framework Improvement Observations

> **Purpose**: During onboarding, note any conventions, tooling patterns, or practices from the adopted project that could improve the process framework itself. Accumulate observations across all three onboarding phases (PF-TSK-064, PF-TSK-065, PF-TSK-066). During PF-TSK-066 Phase 4, approved observations are formalized as PF-IMP entries.
>
> **What to look for**: Build tooling, testing patterns, code organization approaches, CI/CD practices, documentation conventions, developer experience features, naming conventions, or any practice that works well and the framework doesn't currently capture.

| # | Observation | Phase Noted | Potential Benefit | Notes |
|---|-------------|-------------|-------------------|-------|
| 1 | [What the project does well or differently] | [Discovery / Analysis / Documentation] | [How this could improve the framework] | [Additional context] |

---

## Session Log

### Session 1 - [YYYY-MM-DD]

**Phase**: [Current Phase] | **Duration**: [X hours] | **Features**: [IDs]
**Summary**: [What was accomplished; key discoveries]
**Feedback**: [Created / Reference]

### Session 2 - [YYYY-MM-DD]

**Phase**: [Current Phase] | **Duration**: [X hours] | **Features**: [IDs]
**Summary**: [What was accomplished]
**Feedback**: [Created / Reference]

> **Continue adding session entries as needed.**

---

## Completion Summary

> **Fill this section when ALL phases are complete.**

**Total Sessions**: [X]
**Total Time**: [Y hours]
**Started**: [YYYY-MM-DD]
**Completed**: [YYYY-MM-DD]

### Final Metrics

| Metric | Count |
|--------|-------|
| Features with Implementation State Files | [X/N] |
| Codebase File Coverage | [100%] |
| FDDs Created | [X] |
| TDDs Created | [X] |
| Test Specifications Created | [X] |
| ADRs Created | [X] |
| API/DB/UI Designs Created | [X] |
| Total Documents Created | [X] |

### Lessons Learned

- [What worked well in this retrospective process?]
- [What was challenging?]
- [What would be done differently next time?]
- [Recommendations for future framework adoptions]

---

**Status**: [COMPLETE] — Ready to archive to `/temporary/archived/`
