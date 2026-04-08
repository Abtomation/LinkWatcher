---
id: PF-GDE-057
type: Process Framework
category: Guide
version: 1.0
created: 2026-04-05
updated: 2026-04-05
related_task: PF-TSK-064,PF-TSK-065,PF-TSK-066
---

# Onboarding Edge Cases Guide

## Overview

Edge-case guidance for onboarding existing codebases into the process framework. Covers situations where file-to-feature assignment is ambiguous, shared utilities cross feature boundaries, and retroactive documentation must convey confidence levels.

## When to Use

Use this guide during **Codebase Feature Discovery** (PF-TSK-064), **Codebase Feature Analysis** (PF-TSK-065), and **Retrospective Documentation Creation** (PF-TSK-066) when you encounter:

- Source files that don't clearly belong to a single feature
- Utility modules, helpers, or configuration shared across features
- Retroactive design documents where the original rationale is uncertain

## 1. Ambiguous File-to-Feature Assignment

During the file-by-file pass in PF-TSK-064, some files resist clean assignment. Use this decision tree:

### Decision Tree

```
File under review
├─ Does it belong to exactly one feature?
│  └─ Yes → Assign to that feature's "Files Created by" inventory
│
├─ Is it used by multiple features but primarily owned by one?
│  └─ Yes → Assign to the primary owner's "Files Created by"
│           Add to other features' "Files Used by"
│
├─ Is it a shared utility with no clear primary owner?
│  ├─ Is it substantial (>100 lines, distinct responsibility)?
│  │  └─ Yes → Create a "Shared Infrastructure" or "Core Utilities" feature
│  └─ No (small helper, <100 lines)
│     └─ Assign to the feature that uses it most frequently
│        Add to other features' "Files Used by"
│
├─ Is it deprecated or unused?
│  └─ Yes → Note as deprecated in the feature it was originally part of
│           Flag for technical debt assessment
│
└─ Still unclear after the above?
   └─ Flag for human review at the next checkpoint
      Use a provisional assignment and note the uncertainty
```

### Practical Guidelines

| Scenario | Action | Example |
|----------|--------|---------|
| Config file used everywhere | Assign to the feature that owns the config schema; list as "Used by" elsewhere | `config.json` owned by Database Management, used by all |
| Test helper / fixture | Assign to the feature it primarily tests; if cross-cutting, note for cross-cutting test spec | `conftest.py` with shared fixtures |
| Entry point (`main.py`, `app.py`) | Assign to the foundation/application bootstrap feature | `main.py` owned by Application Core (0.1.1) |
| Database migration files | Assign to Database Management feature | `migrations/*.sql` |
| UI utility (formatting, validation) | Assign to the UI feature that uses it most, or to a UI Foundation feature if one exists | `format_currency.py` |

### Key Principle

**Every source file must appear in at least one feature's Code Inventory.** A file listed in "Files Used by" counts as assigned. The goal is 100% coverage, not perfect ownership — provisional assignments can be refined during Feature Analysis (PF-TSK-065).

## 2. Shared Utilities and Cross-Cutting Code

### When to Create a Separate "Shared" Feature

Create a dedicated feature (e.g., "Shared Infrastructure" or "Core Utilities") only when:

1. The shared code has a **distinct responsibility** (logging framework, common data models, utility library)
2. It would have **its own test suite** if tested independently
3. It contains **>3 files or >300 lines** of code collectively
4. Changes to it would require **impact analysis across multiple features**

If none of these apply, distribute the files across existing features using the decision tree above.

### Cross-Cutting Patterns During Analysis (PF-TSK-065)

During Feature Analysis, track cross-cutting patterns in the master state session log:

- **Shared error handling** — same try/catch pattern across features
- **Common data access patterns** — repeated DB query structures
- **Shared configuration loading** — multiple features reading the same config sections
- **Common UI patterns** — reused widget/component patterns

These observations feed into the Retrospective Documentation Creation phase for potential ADRs.

## 3. Confidence Tagging for Retroactive Documentation

When creating FDDs, TDDs, or ADRs for code that already exists, the original design rationale may be unclear. Use confidence tags to communicate certainty levels.

### Confidence Levels

| Level | Tag | Use When |
|-------|-----|----------|
| **High** | `[Confidence: High]` | Design intent is clear from code, comments, commit messages, or existing docs |
| **Medium** | `[Confidence: Medium]` | Design intent is inferred from code patterns and naming but not explicitly documented |
| **Low** | `[Confidence: Low]` | Design intent is speculative — based on code behavior but no supporting evidence |

### Where to Apply Tags

Apply confidence tags in retroactive documentation at the **section level**, not per-sentence:

```markdown
## Design Decisions

### Database Schema Choice [Confidence: High]
SQLite was chosen for single-user local storage. Evidence: README states this explicitly,
and config.json contains sqlite-specific paths.

### Error Handling Strategy [Confidence: Medium]
The codebase uses a centralized try/catch pattern in the main loop, propagating errors
as return codes. Inferred from consistent patterns across 6 modules.

### Invoice Number Format [Confidence: Low]
Invoice numbers appear to follow YYYY-NNN format. No documentation found; inferred
from 3 sample entries in the test database.
```

### Guidelines

- **Don't over-tag**: Only tag sections where confidence is Medium or Low. High-confidence sections don't need tags unless you want to highlight strong evidence.
- **Include evidence**: Always state *why* you assigned that confidence level.
- **Flag Low for review**: Low-confidence sections should be flagged for human review at the next checkpoint.
- **Tags are temporary**: Confidence tags can be removed once a human partner confirms or corrects the content.

## Related Resources

- [Codebase Feature Discovery Task](/process-framework/tasks/00-setup/codebase-feature-discovery.md) — Primary task for file-to-feature assignment
- [Codebase Feature Analysis Task](/process-framework/tasks/00-setup/codebase-feature-analysis.md) — Cross-cutting pattern analysis
- [Retrospective Documentation Creation Task](/process-framework/tasks/00-setup/retrospective-documentation-creation.md) — Where confidence tagging applies
- [Feature Granularity Guide](/process-framework/guides/01-planning/feature-granularity-guide.md) — Criteria for well-scoped features
