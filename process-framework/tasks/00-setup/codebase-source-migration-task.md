---
id: PF-TSK-091
type: Process Framework
category: Task Definition
version: 1.0
created: 2026-06-03
updated: 2026-06-03
description: "Relocate legacy source into the scaffolded per-feature src/ directories during onboarding, file-by-file, with behavior-preserving per-item verification"
---

# Codebase Source Migration

## Purpose & Context

Relocate a project's legacy source into the scaffolded `src/<feature>/` directories during onboarding — **once per project, between [Codebase Feature Discovery (PF-TSK-064)](codebase-feature-discovery.md) and [Codebase Feature Analysis (PF-TSK-065)](codebase-feature-analysis.md)**. Discovery has already assigned every source file to an owning feature (its File Inventory) and scaffolded the empty target directories; this task moves the code in, file-by-file, rewriting every reference and verifying that behavior is preserved.

The work is **behavior-preserving relocation**, not redesign: file contents keep their meaning; only their location and the references to and from them change. For the rationale, background, and split-boundary judgment, see the [Source Migration Guide](../../guides/00-setup/source-migration-guide.md).

> **🚨 Residual-risk reality**: The behavioral gate only protects behavior that tests actually exercise. Moving or splitting thinly-tested legacy code can silently break untested paths. The only mitigation is characterization tests on the units being moved (Step 4). For poorly-tested codebases, migration is necessarily slow and carries irreducible residual risk — surface this to the human partner rather than implying a guarantee. See the [Source Migration Guide](../../guides/00-setup/source-migration-guide.md).

## AI Agent Role

**Role**: Source Migration Engineer
**Mindset**: Behavior-preserving, verification-first, incremental — never move faster than the test baseline can confirm
**Focus Areas**: Import/reference integrity, test-baseline preservation, safe file relocation, split-boundary judgment
**Communication Style**: Surface residual risk on untested code explicitly; bring split-boundary decisions to the human partner; report each item's baseline diff rather than asserting correctness

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/00-setup/codebase-source-migration-map.md)

- **Critical (Must Read):**

  - [Source Migration Guide](../../guides/00-setup/source-migration-guide.md) - Safe-move procedure, split-boundary decisions, the verification stack, residual-risk caveats
  - **Retrospective Master State** (`../../../doc/state-tracking/temporary/retrospective-master-state.md`) - Holds the Source Migration Queue (per-row verification status); built from Discovery's File Inventory
  - **Feature Implementation State files** (`../../../doc/state-tracking/features`) - Each feature's File Inventory is the migration work-list (current path, owning feature, "Files Used by" = inbound references)
  - **Language config** (`../../languages-config/<language>/<language>-config.json`) - `directoryStructure.importRewriteTool` hint for the rewrite approach

- **Important (Load If Space):**

  - [Code Refactoring — Standard Path](../06-maintenance/code-refactoring-standard-path.md) - Provenance of the move/verify discipline restated below (read for deeper rationale; not an operational dependency)
  - [Source Code Layout](../../../doc/technical/architecture/source-code-layout.md) - The target structure files are moved into
  - [Script Development Quick Reference](../../guides/support/script-development-quick-reference.md) - PowerShell execution patterns (check params with `-?`)

- **Reference Only (Access When Needed):**
  - [New-SourceStructure.ps1](../../scripts/file-creation/00-setup/New-SourceStructure.ps1) - `-Update` refreshes the layout directory tree as files land
  - [Validate-OnboardingCompleteness.ps1](../../scripts/validation/Validate-OnboardingCompleteness.ps1) - Confirms Discovery's assignment is 100% before migration begins
  - [Visual Notation Guide](../../guides/support/visual-notation-guide.md) - For interpreting the context map diagram

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including the feedback form are finished.**
>
> **⚠️ MANDATORY: Use automation tools where indicated; never move faster than the per-item baseline diff can confirm.**
>
> **🚨 Never proceed past a `🚨 CHECKPOINT` without presenting findings and getting explicit human approval.**

### Preparation

1. **Confirm prerequisites & the once-per-project guard.**
   - Discovery (PF-TSK-064) is complete: assignment is 100% (run `Validate-OnboardingCompleteness.ps1` — must PASS) and `src/<feature>/` target dirs are scaffolded.
   - **Skip if already migrated**: if no application source remains at legacy/root locations and the Source Migration Queue is 100% verified, this task has already run for the project — stop. Migration runs **once per project**.

2. **Build the Source Migration Queue** in the retrospective master state from each feature's File Inventory. One row per migration **action** (not per file), so n-to-n cases fit:

   | Field | Source |
   |-------|--------|
   | Source path(s) | File Inventory "Files Created by" (primary ownership) |
   | Owning feature | Feature whose state file lists the file |
   | Target path(s) | `src/<feature-slug>/...` (Split → multiple targets) |
   | Action | Move / Split / Co-locate |
   | Refs to update | File Inventory "Files Used by" for the source |
   | Characterization | needed? / created? |
   | Status | ⬜ Pending → 🔄 Moving → ✅ Verified |

3. **🚨 CHECKPOINT**: Present the queue scope (file count, Split rows, units lacking coverage) and the proposed **split-boundary decisions** to the human partner for sign-off before moving anything.

### Execution — per queue item (file-by-file)

> The migration unit is **a file plus every reference to and from it, moved atomically.** Deferring reference updates leaves the tree red. Process one item end-to-end, verify, then take the next. Baselines are captured **per file**, not as one upfront global run — a legacy codebase's test environment is arbitrary and the framework cannot assume a standardized full-suite runner.

4. **Establish the file's local baseline.** Identify the tests that concern the file to be moved — its own tests plus any that import or exercise it — and run them with **the project's actual test mechanism** (whatever the legacy codebase uses; do not assume the framework's `Run-Tests` dispatcher, which the legacy environment may not be wired to). Record the current pass/fail as this item's baseline.
   - **No concerning tests / thin coverage** → write characterization tests first to pin current behavior (a safety net, not a quality judgment). If that is infeasible for this unit, record it and surface the **no-safety-net** risk to the human partner — do not present the move as verified.

5. **Move** the file(s) into the scaffolded target(s).

6. **Rewrite references in BOTH directions.** A move breaks references *to* and *from* the file:
   - **Inbound** (other files → moved file): every caller's import/reference of the moved file → its new path. Include **test-file** imports and mock paths.
   - **Outbound** (moved file → others): the moved file's own imports — **relative imports break** when the file changes directory and must be re-pointed; if a module it imports is *also* being moved, coordinate both. Absolute imports of unmoved modules still resolve.

   Look up `directoryStructure.importRewriteTool` in the project's language config: present (e.g. `libcst`) → use it to rewrite import nodes; `manual`/absent → edit by hand + `grep` for path strings and dynamic/string-based references (which AST tools miss). LinkWatcher assists path-string updates in monitored file types.

7. **Verify against the file's baseline (two layers):**
   - **Static** — run the language's import/build/analyze check (import resolution, `dart analyze`, `tsc --noEmit`, PSScriptAnalyzer). Every reference must resolve; an unresolved reference is a hard, coverage-independent failure.
   - **Behavioral** — re-run the **same concerning tests** from Step 4 and compare to this item's baseline. New failures (relative to the file's baseline) are owned here and must be fixed (or documented as a discovered bug) before advancing.

8. **Record immediately, then advance.** **After every single file move**, update the owning feature's File Inventory paths and mark that queue row ✅ — do not batch these flips. Per-move updates keep the queue an exact record, so nothing is forgotten if a session is interrupted mid-migration.
   - **Split rows** are ✅ only when *all* target pieces are placed, *all* callers are updated, and the local tests pass.

### Finalization

9. **Refresh the layout**: run `New-SourceStructure.ps1 -Update`, which rescans the source tree and regenerates the auto-generated Directory Tree section of `source-code-layout.md` (it never creates or deletes directories):
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/00-setup/New-SourceStructure.ps1 -Update
   ```

10. **Exit gate**: confirm no application source remains at legacy/repository-root locations and the queue is 100% ✅. **If the project has a runnable full test suite**, run it once with the project's own command as a final cross-cutting check (it may not exist for every onboarding project; the per-file checks remain the primary gate). (This is the relocated Discovery Step 7.i conformance check.)

11. **Update the master state**: mark `Phase 1.5: Source Migration` complete, update the `Files Migrated` metric, and set Status to `ANALYSIS`.

12. **🚨 CHECKPOINT**: Present migration results, the final cross-cutting check (if run), and any characterization tests added, for human approval.

13. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below.

## Outputs

- **Relocated source** under `src/<feature>/` — every assigned legacy file moved to its owning feature's directory
- **Updated Feature Implementation State files** — File Inventory paths reflect the new locations
- **Updated Retrospective Master State** — Source Migration Queue 100% ✅, `Phase 1.5` complete, `Files Migrated` metric, Status → `ANALYSIS`
- **Refreshed `source-code-layout.md`** — directory tree regenerated via `New-SourceStructure.ps1 -Update`
- **Characterization tests** (where coverage was thin) — added to lock behavior before moving

## State Tracking

The following state files must be updated as part of this task:

- **Retrospective Master State** (`../../../doc/state-tracking/temporary/retrospective-master-state.md`) - Source Migration Queue rows, `Phase 1.5` checkbox, `Files Migrated` metric, Status field
- **Feature Implementation State files** (`../../../doc/state-tracking/features`) - File Inventory paths updated to the new `src/<feature>/` locations

## ⚠️ MANDATORY Task Completion Checklist

**TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Every Source Migration Queue row is ✅ Verified (Split rows: all pieces placed + all callers updated)
  - [ ] No application source remains at legacy/repository-root locations (exit gate)
  - [ ] Exit-gate cross-cutting check passes — no unowned new failures (a full run if the project has a runnable suite; otherwise the per-file checks)
  - [ ] `source-code-layout.md` directory tree refreshed via `New-SourceStructure.ps1 -Update`
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Retrospective Master State: queue, `Phase 1.5` complete, `Files Migrated` metric, Status → `ANALYSIS`
  - [ ] Feature Implementation State files: File Inventory paths reflect new locations
- [ ] **Complete Feedback Form**: Follow the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md), using task ID "PF-TSK-091" and context "Codebase Source Migration"

## Next Tasks

- [**Codebase Feature Analysis (PF-TSK-065)**](codebase-feature-analysis.md) - Now operates on code in its final `src/<feature>/` locations

## Related Resources

- [Source Migration Guide](../../guides/00-setup/source-migration-guide.md) - The companion how-to (split decisions, verification stack, residual risk)
- [Code Refactoring — Standard Path (PF-TSK-022)](../06-maintenance/code-refactoring-standard-path.md) - Provenance of the move/verify discipline restated above
- [Codebase Feature Discovery (PF-TSK-064)](codebase-feature-discovery.md) - Produces the File Inventory the migration queue is built from
- [Retrospective State Template (PF-TEM-049)](../../templates/00-setup/retrospective-state-template.md) - Defines the master state that hosts the migration queue
