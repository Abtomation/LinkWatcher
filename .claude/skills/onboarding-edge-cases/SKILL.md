---
name: onboarding-edge-cases
description: >-
  Craft for the ambiguous calls during codebase onboarding — file-to-feature assignment when a
  file resists clean ownership, shared-utility handling (when a dedicated Shared Infrastructure
  feature is warranted), cross-cutting pattern tracking during analysis, and confidence tagging
  for retroactive documentation whose original rationale is uncertain. The judgment companion to
  three onboarding tasks: Codebase Feature Discovery (PF-TSK-064), Codebase Feature Analysis
  (PF-TSK-065), and Retrospective Documentation Creation (PF-TSK-066). Activated from those
  tasks' Check-Recommended-Skills steps (via recommended_skills); not a feature-granularity,
  source-migration, or greenfield-planning skill.
user-invocable: false
---

# Onboarding Edge Cases Craft

This skill owns the **edge-case judgment** of codebase onboarding — the calls that arise when
file-to-feature assignment is ambiguous, utilities cross feature boundaries, or retroactive
documentation must convey uncertainty. It serves three tasks, which own everything else (step
sequences, checkpoints, state files): **Codebase Feature Discovery (PF-TSK-064)** consumes the
assignment tree, **Codebase Feature Analysis (PF-TSK-065)** the cross-cutting patterns, and
**Retrospective Documentation Creation (PF-TSK-066)** the confidence tagging.

> **Division of labor.** The tasks own process; this skill owns craft. Still-unclear assignments
> and Low-confidence sections go to the **human partner at the tasks' checkpoints** — the skill
> tells you what to flag, the task tells you when.

## 1. Ambiguous File-to-Feature Assignment

When a file resists clean assignment during the file-by-file pass:

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

| Scenario | Action | Example |
|----------|--------|---------|
| Config file used everywhere | Assign to the feature owning the config schema; list as "Used by" elsewhere | `config.json` owned by Database Management |
| Test helper / fixture | Assign to the feature it primarily tests; if cross-cutting, note for cross-cutting test spec | `conftest.py` with shared fixtures |
| Entry point (`main.py`, `app.py`) | Assign to the foundation/application bootstrap feature | `main.py` owned by Application Core |
| Database migration files | Assign to the Database Management feature | `migrations/*.sql` |
| UI utility | Assign to the UI feature using it most, or a UI Foundation feature if one exists | `format_currency.py` |

**Key principle**: every source file must appear in at least one feature's Code Inventory — a
"Files Used by" listing counts as assigned. The goal is **100% coverage, not perfect
ownership**; provisional assignments are refined during Feature Analysis.

## 2. Shared Utilities and Cross-Cutting Code

Create a dedicated shared feature ("Shared Infrastructure" / "Core Utilities") **only** when the
shared code has a distinct responsibility (logging framework, common data models, utility
library), would have its own test suite if tested independently, contains >3 files or >300 lines
collectively, and changes to it would need impact analysis across multiple features. Otherwise
distribute the files via the decision tree above.

**During Analysis**, track cross-cutting patterns in the master state session log — shared error
handling, common data-access patterns, shared configuration loading, common UI patterns. These
observations feed Retrospective Documentation Creation as potential ADRs.

## 3. Confidence Tagging for Retroactive Documentation

When creating FDDs/TDDs/ADRs for existing code whose original rationale is unclear:

| Level | Tag | Use when |
|-------|-----|----------|
| **High** | `[Confidence: High]` | Intent clear from code, comments, commit messages, or existing docs |
| **Medium** | `[Confidence: Medium]` | Intent inferred from code patterns and naming, not explicitly documented |
| **Low** | `[Confidence: Low]` | Intent speculative — based on behavior, no supporting evidence |

Apply tags at the **section level**, not per-sentence:

```markdown
### Error Handling Strategy [Confidence: Medium]
Centralized try/catch in the main loop, propagating errors as return codes.
Inferred from consistent patterns across 6 modules.
```

Guidelines: don't over-tag (tag Medium/Low only, unless highlighting strong evidence); always
state *why* the level was assigned; flag Low-confidence sections for human review at the next
checkpoint; tags are temporary — remove them once the human partner confirms or corrects the
content.
