---
id: PD-STA-015
type: Process Framework
category: State File
version: 2.0
created: 2025-07-25
updated: 2026-04-12
tracking_scope: Cross-cutting architectural decisions (ADR registry)
state_type: Architecture Decision Tracking
---

# Architecture Decision Tracking

This file is the **authoritative cross-cutting ADR registry** for the project. All Architecture Decision Records are indexed here regardless of which feature they relate to. ADRs have an N:M relationship with features — one ADR can span multiple features, and one feature can have multiple ADRs.

## Relationship to Feature Tracking

- **Architecture Tracking (this file)**: Sole registry for all ADRs — the source of truth for "what architectural decisions exist"
- **Feature Tracking**: Tracks feature implementation status. Does not track ADRs per-feature (removed in v2.0 — N:M relationship makes per-feature columns misleading)
- **Feature State Files**: Individual feature state files may reference relevant ADRs in their documentation inventory

## ADR Index

| ADR ID | Title | Status | Related Features | Date |
|--------|-------|--------|-----------------|------|
| [PD-ADR-039](/doc/technical/adr/orchestrator-facade-pattern-for-core-architecture.md) | Orchestrator/Facade Pattern for Core Architecture | Accepted | 0.1.1 | 2026-02-19 |
| [PD-ADR-040](/doc/technical/adr/target-indexed-in-memory-link-database.md) | Target-Indexed In-Memory Link Database | Accepted | 0.1.2 | 2026-02-19 |
| [PD-ADR-041](/doc/technical/adr/timer-based-move-detection-with-3-phase-directory-batch-algorithm.md) | Timer-Based Move Detection with 3-Phase Directory Batch Algorithm | Accepted | 1.1.1 | 2026-03-27 |

> New ADRs are automatically appended to this index by `New-ArchitectureDecision.ps1`.

## ADR Status Legend

| Status | Description |
|--------|-------------|
| Proposed | Decision documented, awaiting approval |
| Accepted | Decision approved and guiding implementation |
| Deprecated | Decision no longer applies (superseded or context changed) |
| Superseded | Replaced by a newer ADR (link to successor) |

## Creating ADRs

ADRs are created **inline** during tasks where architectural decisions arise — there is no separate ADR creation task. Use the script and follow the guide:

```bash
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/02-design/New-ArchitectureDecision.ps1 -Title "Decision Title" -Status "Proposed" -Confirm:\$false
```

**Guide**: [Architecture Decision Creation Guide](/process-framework/guides/02-design/architecture-decision-creation-guide.md) — follow for content customization, quality assurance, and validation criteria.

**When to create ADRs**:
- During implementation when a significant architectural decision is made (pattern choice, technology selection, structural trade-off)
- When System Architecture Review identifies architectural choices worth documenting
- When refactoring changes design patterns or module boundaries
- When a bug fix introduces a new architectural pattern

> ADRs are lightweight artifacts. Not every design decision needs one — only decisions that have long-term impact, involved trade-offs between alternatives, or would surprise a future developer.

## Related Documentation

### Essential Guides
- [Architectural Framework Usage Guide](/process-framework/guides/01-planning/architectural-framework-usage-guide.md) - Comprehensive guide for using the architectural framework
- [Architecture Decision Creation Guide](/process-framework/guides/02-design/architecture-decision-creation-guide.md) - Step-by-step guide for creating and customizing ADRs

### Primary Tracking
- [Feature Tracking](feature-tracking.md) - Primary tracking for all features including foundation (0.x.x)

## Tasks That Update This File

- [New-ArchitectureDecision.ps1](/process-framework/scripts/file-creation/02-design/New-ArchitectureDecision.ps1): Auto-appends new ADRs to the ADR Index
- [System Architecture Review](/process-framework/tasks/01-planning/system-architecture-review.md): May create ADRs during architectural analysis
- [Foundation Feature Implementation](/process-framework/tasks/04-implementation/foundation-feature-implementation-task.md): May create ADRs during foundation work
- [Code Refactoring (Standard Path)](/process-framework/tasks/06-maintenance/code-refactoring-standard-path.md): May create ADRs when changing patterns

## Update History

| Date | Change | Updated By |
|------|--------|------------|
| 2026-04-12 | v2.0 — **ADR Infrastructure Consolidation** (PF-PRO-019): Redesigned as authoritative cross-cutting ADR registry. Populated ADR Index with 3 existing ADRs. Removed empty Current Architecture State, Architecture Sessions Summary, and Architecture Context Packages sections. Updated ADR creation guidance to inline pattern (script + guide). | [Framework Extension (PF-TSK-026)](../../../process-framework/tasks/support/framework-extension-task.md) |
