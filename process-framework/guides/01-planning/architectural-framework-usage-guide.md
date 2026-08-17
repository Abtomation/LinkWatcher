---
id: PF-GDE-056
type: Process Framework
category: Guide
version: 2.0
created: 2025-08-02
updated: 2026-06-16
related_task: PF-TSK-019,PF-TSK-024
description: "Conceptual reference for the Architectural Integration Framework — its components and the context-loading priority order for cross-cutting architectural work"
---

# Architectural Integration Framework — Reference

A conceptual reference for the **Architectural Integration Framework**: the set of artifacts that give AI agents continuity and bounded context when working on cross-cutting architectural work (foundation features, system-architecture reviews). The operative procedures live in the owning tasks and templates linked below — this page is the map of how those pieces fit together, not a restatement of their steps.

## Components

- **Architecture Tracking** ([architecture-tracking.md](../../../doc/state-tracking/permanent/architecture-tracking.md)) — cross-cutting architectural state: the current architecture-state table, the ADR index, and per-session summaries.
- **Architecture Context Packages** — bounded, AI-digestible contexts for one architectural area (current focus, key decisions, implementation status, next-agent instructions). Their structure, size target (~100–120 lines), and update procedure are owned by the [Architecture Context Package Update Template (PF-TEM-031)](../../templates/02-design/architecture-context-package-update-template.md).
- **Architecture Decision Records (ADRs)** — significant architectural decisions ([ADR template](../../templates/02-design/adr-template.md)); status flows Proposed → Accepted → Superseded and is indexed from Architecture Tracking.
- **Foundation-feature integration** — architectural (0.x.x) implementation runs through the [Foundation Feature Implementation Task](../../tasks/04-implementation/foundation-feature-implementation-task.md); cross-cutting analysis runs through the [System Architecture Review Task](../../tasks/01-planning/system-architecture-review.md).

## When the framework applies

- Foundation features (0.x.x) that establish architectural patterns or make cross-cutting decisions impacting multiple features.
- System architecture reviews where new features affect system architecture or architectural decisions are needed.

## Context-loading priority order

When starting architectural work, load context in this order (highest first), stopping when the context budget is reached:

1. Architecture Context Package (the bounded context for the area)
2. Architecture Tracking (current architectural state)
3. Related ADRs (key decisions)
4. Feature Dependencies (impact understanding)
5. Implementation details (as space allows)

## Where the procedures live

| You need to… | Go to |
|---|---|
| Run architectural analysis for a new/changed feature | [System Architecture Review Task](../../tasks/01-planning/system-architecture-review.md) |
| Implement a foundation (0.x.x) feature | [Foundation Feature Implementation Task](../../tasks/04-implementation/foundation-feature-implementation-task.md) |
| Create or update an Architecture Context Package | [Architecture Context Package Update Template (PF-TEM-031)](../../templates/02-design/architecture-context-package-update-template.md) |
| Record an architectural decision | [ADR template](../../templates/02-design/adr-template.md) |
| See current architectural state / session history | [Architecture Tracking](../../../doc/state-tracking/permanent/architecture-tracking.md) |
