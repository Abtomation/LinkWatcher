# Retrospective Documentation Task - Concept Document

## Created
2026-02-17

## Updated
2026-02-17 (v2.0 - Codebase-wide orchestration approach)

> **Note**: This concept document has been superseded. PF-TSK-060 has been further split into three onboarding tasks:
> - [Codebase Feature Discovery (PF-TSK-064)](../tasks/00-onboarding/codebase-feature-discovery.md)
> - [Codebase Feature Analysis (PF-TSK-065)](../tasks/00-onboarding/codebase-feature-analysis.md)
> - [Retrospective Documentation Creation (PF-TSK-066)](../tasks/00-onboarding/retrospective-documentation-creation.md)
>
> This document is retained as a concept reference explaining the rationale and evolution of the approach.

## Purpose

Define the process for adopting the process framework into an existing, ongoing project. This task systematically documents the entire codebase by identifying all features, assigning every source file to a feature, creating Feature Implementation State files, and then producing the required design documentation.

## Problem Statement

When the process framework is copied into an existing project, there is a gap: the project has working code but no framework-aligned documentation. This creates several issues:

1. **Knowledge Gap**: No documented requirements or technical design for existing features
2. **Inconsistent Documentation**: Future features will have comprehensive documentation, creating inconsistency with existing features
3. **Maintenance Challenges**: Difficult to modify or extend existing features without design context
4. **AI Agent Continuity**: AI agents lack design context when working with existing features
5. **No Code Ownership Mapping**: Unknown which files belong to which features

## Solution: Codebase-Wide Retrospective Documentation

### Core Approach

The task operates as a **codebase-wide orchestration** across many sessions, not as a per-feature task. The key insight is that ALL features must be discovered and ALL code must be assigned before deep documentation begins.

### Four-Phase Process

**Phase 1: Feature Discovery & Code Assignment**
- Scan the entire codebase to identify all features
- Create Feature Implementation State files for EVERY feature (including Tier 1)
- Assign every source file to at least one feature's Code Inventory
- List all files in the master state file; track coverage percentage until 100% is achieved
- Excludes `doc/` directory (process framework) — only source code, tests, config, scripts

**Phase 2: Analysis**
- For each feature: analyze architecture, data flow, dependencies, patterns
- Enrich Feature Implementation State files with design decisions and patterns

**Phase 3: Tier Assessment & Documentation Creation**
- For each feature: assess tier (or validate existing assessment), then create required documents
- Uses [Feature Tier Assessment Task](../tasks/01-planning/feature-tier-assessment-task.md) for assessments
- Creates FDD, TDD, Test Specifications, ADRs based on tier requirements
- Priority order: Foundation → Tier 3 → Tier 2 (skip Tier 1 for documentation)

**Phase 4: Finalization**
- Verify completeness (100% coverage, all docs created, all links in tracking)
- Archive master state file

### Key Design Decisions

**All features get implementation state files** (including Tier 1):
- Enables 100% codebase coverage tracking
- Every file can be traced to its owning feature
- Tier 1 files are lightweight (just Code Inventory section)

**Process all features through each phase before advancing**:
- Phase 1 for all features gives a complete picture before deep analysis
- Prevents the scenario where documenting feature A reveals it should be structured differently
- Tier assessment for all features determines full documentation scope before starting Phase 4

**Master state file tracks everything**:
- One file for the entire retrospective effort (not per-feature)
- Coverage metrics, feature inventory tables, session log
- Supersedes any previous integration state files

**Feedback forms after every session**:
- Continuous process improvement, not just end-of-task reflection

### Key Differences from Forward Documentation

| Aspect | Forward Workflow | Retrospective Workflow |
|--------|------------------|------------------------|
| **Scope** | One feature at a time | Entire codebase |
| **Design Documents** | Created BEFORE code | Created AFTER code |
| **Source of Truth** | Design specs | Implemented code |
| **Documentation Type** | Prescriptive ("should") | Descriptive ("is") |
| **Analysis Tool** | Implementation Planning | Feature Implementation State |
| **Approach** | Plan → Build | Discover → Assign → Analyze → Assess → Document |
| **Unknowns** | Design decisions to be made | Design decisions to discover |
| **Coverage Goal** | Single feature complete | 100% codebase file assignment |

## Outputs

- **Feature Implementation State Files** (one per feature) - permanent code inventory
- **Retrospective Master State File** - temporary session tracking (archived when complete)
- **Functional Design Documents** (Tier 2+)
- **Technical Design Documents** (Tier 2+)
- **Test Specifications** (Tier 3)
- **Architecture Decision Records** (Foundation 0.x.x)
- **Conditional documents** (API, DB, UI designs per assessment)

All documents are marked "Retrospective" and use existing templates/creation tasks.

## Session Estimates

| Project Size | Features | Estimated Sessions |
|---|---|---|
| Small | 5-10 | 5-10 sessions |
| Medium | 20-30 | 15-25 sessions |
| Large | 40+ | 25-40+ sessions |

## References

- [Retrospective Feature Documentation Task (PF-TSK-060)](../tasks/cyclical/retrospective-feature-documentation-task.md) - **Authoritative task definition**
- [Retrospective Master State Template](../templates/templates/retrospective-state-template.md) - Master tracking template
- [Feature Implementation State Template](../templates/templates/feature-implementation-state-template.md) - Per-feature code analysis template
- [Feature Tracking](../state-tracking/permanent/feature-tracking.md) - Feature status tracking
- [Retrospective Task Redesign Summary](retrospective-task-redesign-summary.md) - Historical v1.0 redesign notes
