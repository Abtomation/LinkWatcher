---
id: PD-STA-002
type: Process Framework
category: State Tracking
version: 1.2
created: 2025-06-15
updated: 2026-06-10
---

# Technical Debt Tracker

This document tracks technical debt. As a solo developer, it's important to be intentional about technical debt - sometimes taking shortcuts is necessary to make progress, but these should be documented and addressed later.

## What is Technical Debt?

Technical debt refers to the implied cost of future rework caused by choosing an easy or quick solution now instead of a better approach that would take longer. It's not inherently bad, but it should be managed.

## Technical Debt Dimensions

Technical debt items are tagged with **Primary Dimension** using the standard abbreviations from the [Development Dimensions Guide](/process-framework/guides/framework/development-dimensions-guide.md), plus **TST** (Testing) and **AIC** (AI Agent Continuity) for non-dimension debt.

**Valid values**: AC, CQ, ID, DA, EM, SE, PE, OB, UX, DI, TST, AIC

> **Note**: Resolved items (in the collapsed section below) retain their legacy Category names for historical accuracy.

## Priority Levels

- **Critical**: Must be addressed before the next release
- **High**: Should be addressed in the next development cycle
- **Medium**: Should be addressed when convenient
- **Low**: Nice to fix, but not urgent

## Technical Debt Registry

| ID    | Description                                                | Dims        | Location                                                                     | Created Date | Priority | Estimated Effort | Status      | Resolution Date | Assessment ID | Workflows | Notes                                                                                                |
| ----- | ---------------------------------------------------------- | ----------- | ---------------------------------------------------------------------------- | ------------ | -------- | ---------------- | ----------- | --------------- | ------------- | --------- | ---------------------------------------------------------------------------------------------------- |
| TD260 | No automated end-to-end regression that two near-simultaneous daemon starts yield exactly one daemon per project root. PD-BUG-100's tests pin the launcher cleanup decision (TE-TST-135) and the release_lock/launcher lock-preservation decision in isolation, not the real concurrent-start to single-daemon outcome (the bug's literal symptom). | TST DI | process-framework/tools/linkWatcher/start_linkwatcher_background.ps1 + main.py acquire_lock (concurrent-start path) | 2026-06-08 | Low | M (~3-5h; concurrency harness is flaky-prone) | Open | - | - | - | Surfaced in PD-BUG-100 code review (PF-TSK-005) 2026-06-08; author pinned the precise defective decision instead of building the harness. Cross-ref PD-BUG-100 (Closed). |
| TD261 | Config schema drift guard (test_configschemadrift.py, TE-TST-136) compares set/dict-valued defaults by key presence only, not value — missing a fully-inlined-list value check. Currently masks live drift in configuration-guide.md ignored_directories vs LinkWatcherConfig default. Extend guard to value-compare set/dict defaults for guide fields listed without an abbreviation marker. | TST | test/automated/unit/0-system-architecture-foundation/0-0-system-architecture-foundation/test_configschemadrift.py | 2026-06-10 | Low | Small | Open | - | - | - | Surfaced by Test Audit TE-TAR-075 (feature 0.1.3). Routed to PF-TSK-022 (test-only Lightweight path). |

## Recently Resolved Technical Debt

> 🗄️ **Archived** — Resolved and rejected debt rows live in [archive/technical-debt-tracking-archive.md](archive/technical-debt-tracking-archive.md) (sibling file, split 2026-05-26 per PF-IMP-873 to keep this file scannable as resolved history grows; PRJ-001's resolved section reached 73% of file size before split).
>
> `Update-TechDebt.ps1` reads and writes the archive automatically when transitioning to `Resolved` / `Rejected` and when using `-Section "Resolved" -ResolvedDebtId -UpdateNotes` for post-resolution notes. The archive holds two sections: `## Resolved` (debt paid down) and `## Rejected` (won't-fix / accepted-as-design) — kept distinct so trend analysis can separate "we paid it down" from "we decided not to."

## Technical Debt Management Strategy

As a solo developer, follow these guidelines for managing technical debt:

1. **Be intentional**: When creating technical debt, do so consciously and document it immediately
2. **Comment in code**: Mark technical debt in code with `// TODO: [TD###] Description` comments
3. **Regular review**: Review this document periodically to reassess priorities
4. **Batch similar items**: Address similar technical debt items together for efficiency
5. **Refactoring sessions**: Dedicate occasional focused sessions to addressing technical debt

## Linking with Assessment System

**Assessment ID Column**: Links debt items to their originating technical debt assessments:

- **Assessment IDs**: Use format `PF-TDA-XXX` for items identified during formal assessments
- **Debt Item IDs**: Individual debt items get `PF-TDI-XXX` IDs during assessment
- **Manual Items**: Items identified outside assessments leave Assessment ID blank (`-`)

**Workflow Integration**:

1. During Technical Debt Assessment, individual debt items are created with `PF-TDI-XXX` IDs
2. Assessment generates report with `PF-TDA-XXX` ID
3. When adding items to this registry, reference the assessment ID in the Assessment ID column
4. This creates traceability from registry entries back to detailed assessment documentation

## Adding New Technical Debt Items

When adding a new technical debt item:

1. Assign the next available ID (TD###)
2. Add a detailed description
3. Categorize it appropriately
4. Note the exact location in code
5. Assign a priority
6. Estimate the effort required to fix it
7. Add any relevant notes
8. Add a corresponding comment in the code

## Resolving Technical Debt Items

Use [Update-TechDebt.ps1](../../../process-framework/scripts/update/Update-TechDebt.ps1) to automate steps 1-4:

```powershell
# Mark as in progress
Update-TechDebt.ps1 -DebtId "TD###" -NewStatus "InProgress"

# Resolve (moves to Recently Resolved, sets date)
Update-TechDebt.ps1 -DebtId "TD###" -NewStatus "Resolved" -ResolutionNotes "What was done."

# Resolve with plan link
Update-TechDebt.ps1 -DebtId "TD###" -NewStatus "Resolved" -ResolutionNotes "What was done." -PlanLink "[TD###](../../refactoring/plans/your-plan-file.md)"
```

After running the script:
5. Remove the corresponding TODO comment from the code

---

_This document is part of the Process Framework and provides a system for tracking and managing technical debt._
