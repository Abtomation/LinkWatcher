---
id: PF-TEM-044
type: Process Framework
category: Template
version: 1.0
created: 2026-02-17
updated: 2026-02-17
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
- [Codebase Feature Discovery (PF-TSK-064)](../../tasks/00-onboarding/codebase-feature-discovery.md)
- [Codebase Feature Analysis (PF-TSK-065)](../../tasks/00-onboarding/codebase-feature-analysis.md)
- [Retrospective Documentation Creation (PF-TSK-066)](../../tasks/00-onboarding/retrospective-documentation-creation.md)

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

> **Target**: This section should be EMPTY when Phase 1 is complete.
> List all project source files not yet assigned to any feature's Code Inventory.

| File Path | Notes | Candidate Feature |
|-----------|-------|-------------------|
| [path/to/file.ext] | [note about what this file does] | [suggested feature ID] |

---

## Session Log

### Session 1 - [YYYY-MM-DD]

**Phase**: [Current Phase]
**Duration**: [X hours]
**Features Worked On**: [List of feature IDs]

**Progress**:
- [What was accomplished]
- [Coverage change: X% → Y%]
- [Key discoveries]

**Next Steps**:
- [Specific actions for next session]
- [Features to process next]

**Feedback Form**: [Created / Reference]

---

### Session 2 - [YYYY-MM-DD]

**Phase**: [Current Phase]
**Duration**: [X hours]
**Features Worked On**: [List of feature IDs]

**Progress**:
- [What was accomplished]

**Next Steps**:
- [Specific actions for next session]

**Feedback Form**: [Created / Reference]

---

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
