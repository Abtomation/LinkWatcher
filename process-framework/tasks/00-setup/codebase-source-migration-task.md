---
id: PF-TSK-091
type: Process Framework
category: Task Definition
version: 1.1
created: 2026-06-03
updated: 2026-07-13
change_notes: "v1.1 - Check Recommended Skills wiring (Step 1, renumber): source-migration craft skill replaces the retired Source Migration Guide (Craft-as-Skill BL-5 batch 5)"
description: "Relocate legacy source into the scaffolded per-feature src/ directories during onboarding, file-by-file, with behavior-preserving per-item verification"
complexity: medium
use_when: >-
  Relocate legacy source into the scaffolded per-feature src/ directories during onboarding, file-by-file, with behavior-preserving per-item verification
automation: manual
scripts:
  - ../../scripts/file-creation/00-setup/New-SourceStructure.ps1
  - ../../scripts/validation/Validate-OnboardingCompleteness.ps1
trigger_status:
  - raw: "`retrospective-master-state.md` → Phase 1 = `100%` (Discovery complete; Status set to `SOURCE_MIGRATION`)"
output_status:
  - raw: "`retrospective-master-state.md` → `Phase 1.5` = complete, Source Migration Queue 100% ✅, Status → `ANALYSIS`; Feature Implementation State files' File Inventory paths updated to `src/<feature>/`"
next_tasks:
  - task: codebase-feature-analysis.md
    condition: "Now operates on code in its final `src/<feature>/` locations"
---

# Codebase Source Migration

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

Relocate a project's legacy source into the scaffolded `src/<feature>/` directories during onboarding — **once per project, between [Codebase Feature Discovery (PF-TSK-064)](codebase-feature-discovery.md) and [Codebase Feature Analysis (PF-TSK-065)](codebase-feature-analysis.md)**. Discovery has already assigned every source file to an owning feature (its File Inventory) and scaffolded the empty target directories; this task moves the code in, file-by-file, rewriting every reference and verifying that behavior is preserved.

The work is **behavior-preserving relocation**, not redesign: file contents keep their meaning; only their location and the references to and from them change. For the rationale, background, and split-boundary judgment, apply the [`source-migration` craft skill](../../../.claude/skills/source-migration/SKILL.md) (activated at Step 1).

> **🚨 Residual-risk reality**: The behavioral gate only protects behavior that tests actually exercise. Moving or splitting thinly-tested legacy code can silently break untested paths. The only mitigation is characterization tests on the units being moved (Step 5). For poorly-tested codebases, migration is necessarily slow and carries irreducible residual risk — surface this to the human partner rather than implying a guarantee. See the [`source-migration` craft skill](../../../.claude/skills/source-migration/SKILL.md).

## AI Agent Role

**Role**: Source Migration Engineer
**Mindset**: Behavior-preserving, verification-first, incremental — never move faster than the test baseline can confirm
**Focus Areas**: Import/reference integrity, test-baseline preservation, safe file relocation, split-boundary judgment
**Communication Style**: Surface residual risk on untested code explicitly; bring split-boundary decisions to the human partner; report each item's baseline diff rather than asserting correctness

## Context Requirements

- **Critical (Must Read):**

  - [`source-migration` craft skill](../../../.claude/skills/source-migration/SKILL.md) - The migration judgment craft (action classification, split-boundary decisions, the verification stack, residual-risk caveats), activated in Step 1 (Check Recommended Skills). Replaces the retired Source Migration Guide.
  - **Retrospective Master State** (`../../../doc/state-tracking/temporary/retrospective-master-state.md`) - Holds the Source Migration Queue (per-row verification status); built from Discovery's File Inventory
  - **Feature Implementation State files** (`../../../doc/state-tracking/features`) - Each feature's File Inventory is the migration work-list (current path, owning feature, "Files Used by" = inbound references)
  - **Language config** (`../../languages-config/<language>/<language>-config.json`) - `directoryStructure.importRewriteTool` hint for the rewrite approach

- **Important (Load If Space):**

  - [Code Refactoring — Standard Path](../06-maintenance/code-refactoring-standard-path.md) - Provenance of the move/verify discipline restated below (read for deeper rationale; not an operational dependency)
  - [Source Code Layout](../../../doc/technical/architecture/source-code-layout.md) - The target structure files are moved into
  - [Script Development Quick Reference](../../guides/support/script-development-quick-reference.md) - PowerShell execution patterns (check params with `Get-Help <script> -Parameter *`)

- **Reference Only (Access When Needed):**
  - [New-SourceStructure.ps1](../../scripts/file-creation/00-setup/New-SourceStructure.ps1) - `-Update` refreshes the layout directory tree as files land
  - [Validate-OnboardingCompleteness.ps1](../../scripts/validation/Validate-OnboardingCompleteness.ps1) - Confirms Discovery's assignment is 100% before migration begins

## Process

> **⚠️ MANDATORY: Use automation tools where indicated; never move faster than the per-item baseline diff can confirm.**
>
> **🚨 Never proceed past a `🚨 CHECKPOINT` without presenting findings and getting explicit human approval.**

### Preparation

1. **Check Recommended Skills**: Read the active language-config (`languages-config/{language}/{language}-config.json`) and `project-config.json` for `recommended_skills` entries keyed to `codebase-source-migration-task`. If the `source-migration` craft skill is available in the session, activate it — it owns the **migration judgment craft** this task delegates to (action classification, split-boundary decisions, the three-layer verification stack, both-direction import rewriting, residual-risk honesty). If it is not listed in the session, read [`SKILL.md`](../../../.claude/skills/source-migration/SKILL.md) directly and apply it — that file is the canonical source the Skill tool loads, so a direct read is equivalent, not degraded. The craft is unavailable for this run only if the skill file itself is absent (the retired procedural guide has no successor).

2. **Confirm prerequisites & the once-per-project guard.**
   - Discovery (PF-TSK-064) is complete: assignment is 100% (run `Validate-OnboardingCompleteness.ps1` — must PASS) and `src/<feature>/` target dirs are scaffolded.
   - **Skip if already migrated**: if no application source remains at legacy/root locations and the Source Migration Queue is 100% verified, this task has already run for the project — stop. Migration runs **once per project**.

3. **Build the Source Migration Queue** in the retrospective master state from each feature's File Inventory. One row per migration **action** (not per file), so n-to-n cases fit:

   | Field | Source |
   |-------|--------|
   | Source path(s) | File Inventory "Files Created by" (primary ownership) |
   | Owning feature | Feature whose state file lists the file |
   | Target path(s) | `src/<feature-slug>/...` (Split → multiple targets) |
   | Action | Move / Split / Co-locate |
   | Refs to update | File Inventory "Files Used by" for the source |
   | Characterization | needed? / created? |
   | Status | ⬜ Pending → 🔄 Moving → ✅ Verified |

4. **🚨 CHECKPOINT**: Present the queue scope (file count, Split rows, units lacking coverage) and the proposed **split-boundary decisions** to the human partner for sign-off before moving anything.

### Execution — per queue item (file-by-file)

> The migration unit is **a file plus every reference to and from it, moved atomically.** Deferring reference updates leaves the tree red. Process one item end-to-end, verify, then take the next. Baselines are captured **per file**, not as one upfront global run — a legacy codebase's test environment is arbitrary and the framework cannot assume a standardized full-suite runner.

5. **Establish the file's local baseline.** Identify the tests that concern the file to be moved — its own tests plus any that import or exercise it — and run them with **the project's actual test mechanism** (whatever the legacy codebase uses; do not assume the framework's `Run-Tests` dispatcher, which the legacy environment may not be wired to). Record the current pass/fail as this item's baseline.
   - **No concerning tests / thin coverage** → write characterization tests first to pin current behavior (a safety net, not a quality judgment). If that is infeasible for this unit, record it and surface the **no-safety-net** risk to the human partner — do not present the move as verified.

6. **Move** the file(s) into the scaffolded target(s).

7. **Rewrite references in BOTH directions.** A move breaks references *to* and *from* the file:
   - **Inbound** (other files → moved file): every caller's import/reference of the moved file → its new path. Include **test-file** imports and mock paths.
   - **Outbound** (moved file → others): the moved file's own imports — **relative imports break** when the file changes directory and must be re-pointed; if a module it imports is *also* being moved, coordinate both. Absolute imports of unmoved modules still resolve.

   Look up `directoryStructure.importRewriteTool` in the project's language config: present (e.g. `libcst`) → use it to rewrite import nodes; `manual`/absent → edit by hand + `grep` for path strings and dynamic/string-based references (which AST tools miss). LinkWatcher assists path-string updates in monitored file types — which patterns it updates automatically vs. what needs manual handling: `<LinkWatcher install>/doc/user/handbooks/linkwatcher-capabilities-reference.md` (install default `%USERPROFILE%\bin`, override via `LINKWATCHER_INSTALL_DIR`).

8. **Verify against the file's baseline (two layers):**
   - **Static** — run the language's import/build/analyze check (import resolution, `dart analyze`, `tsc --noEmit`, PSScriptAnalyzer). Every reference must resolve; an unresolved reference is a hard, coverage-independent failure.
   - **Behavioral** — re-run the **same concerning tests** from Step 5 and compare to this item's baseline. New failures (relative to the file's baseline) are owned here and must be fixed (or documented as a discovered bug) before advancing.

9. **Record immediately, then advance.** **After every single file move**, update the owning feature's File Inventory paths and mark that queue row ✅ — do not batch these flips. Per-move updates keep the queue an exact record, so nothing is forgotten if a session is interrupted mid-migration.
   - **Split rows** are ✅ only when *all* target pieces are placed, *all* callers are updated, and the local tests pass.

### Finalization

10. **Refresh the layout**: run `New-SourceStructure.ps1 -Update`, which rescans the source tree and regenerates the auto-generated Directory Tree section of `source-code-layout.md` (it never creates or deletes directories):
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/00-setup/New-SourceStructure.ps1 -Update
   ```

11. **Exit gate**: confirm no application source remains at legacy/repository-root locations and the queue is 100% ✅. **If the project has a runnable full test suite**, run it once with the project's own command as a final cross-cutting check (it may not exist for every onboarding project; the per-file checks remain the primary gate). (This is the relocated Discovery Step 7.i conformance check.)

12. **Update the master state**: mark `Phase 1.5: Source Migration` complete, update the `Files Migrated` metric, and set Status to `ANALYSIS`.

13. **🚨 CHECKPOINT**: Present migration results, the final cross-cutting check (if run), and any characterization tests added, for human approval.

14. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below.

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

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Every Source Migration Queue row is ✅ Verified (Split rows: all pieces placed + all callers updated)
  - [ ] No application source remains at legacy/repository-root locations (exit gate)
  - [ ] Exit-gate cross-cutting check passes — no unowned new failures (a full run if the project has a runnable suite; otherwise the per-file checks)
  - [ ] `source-code-layout.md` directory tree refreshed via `New-SourceStructure.ps1 -Update`
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Retrospective Master State: queue, `Phase 1.5` complete, `Files Migrated` metric, Status → `ANALYSIS`
  - [ ] Feature Implementation State files: File Inventory paths reflect new locations
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-091`, context "Codebase Source Migration".

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Moves** | Legacy/root source files → `src/<feature>/` | Manual (per queue row) | One migration action at a time; references rewritten inbound + outbound; verified against per-file baseline before advancing |
| **Updates** | Retrospective Master State File | Manual | Source Migration Queue rows ⬜→🔄→✅; `Phase 1.5` complete; `Files Migrated` metric; Status → `ANALYSIS` |
| **Updates** | Feature Implementation State Files | Manual | File Inventory paths updated to new `src/<feature>/` locations (per-move, not batched) |
| **Updates** | [`source-code-layout.md`](../../../doc/technical/architecture/source-code-layout.md) | `New-SourceStructure.ps1 -Update` | Regenerates the auto-generated Directory Tree section as files land |
| **Creates** | Characterization tests (where coverage is thin) | Manual | Pin current behavior before moving a thinly-tested unit |

## Next Tasks

- [**Codebase Feature Analysis (PF-TSK-065)**](codebase-feature-analysis.md) - Now operates on code in its final `src/<feature>/` locations

<!-- merged from transition-registry entry: Codebase Source Migration (PF-TSK-091) -->
### Prerequisites for Transition

- [ ] Source Migration Queue is 100% ✅ Verified (Split rows: all target pieces placed + all callers updated)
- [ ] No application source remains at legacy/repository-root locations (exit-gate conformance check, relocated from Discovery Step 7.i)
- [ ] Exit-gate cross-cutting check passed — no unowned new failures (a full suite run if the project has one; otherwise the per-file checks are the primary gate)
- [ ] Feature Implementation State files' File Inventory paths updated to the new `src/<feature>/` locations
- [ ] `source-code-layout.md` directory tree refreshed via `New-SourceStructure.ps1 -Update`
- [ ] `Phase 1.5: Source Migration` marked complete in master state

### Next Task Selection

- **Always**: → [Codebase Feature Analysis (PF-TSK-065)](codebase-feature-analysis.md)

### Preparation for Next Task

1. Verify master state shows `Phase 1.5` complete and Status set to "ANALYSIS"
2. Review Feature Tracking for the full feature list to analyze
3. Identify feature categories for batching analysis sessions

## Related Resources

- [`source-migration` craft skill](../../../.claude/skills/source-migration/SKILL.md) - The migration judgment craft (split decisions, verification stack, residual risk); replaces the retired Source Migration Guide
- [Code Refactoring — Standard Path (PF-TSK-022)](../06-maintenance/code-refactoring-standard-path.md) - Provenance of the move/verify discipline restated above
- [Codebase Feature Discovery (PF-TSK-064)](codebase-feature-discovery.md) - Produces the File Inventory the migration queue is built from
- [Retrospective State Template (PF-TEM-049)](../../templates/00-setup/retrospective-state-template.md) - Defines the master state that hosts the migration queue
