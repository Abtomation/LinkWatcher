---
id: PF-GDE-070
type: Process Framework
category: Guide
version: 1.0
created: 2026-06-03
updated: 2026-06-03
related_task: PF-TSK-091
description: Safe behavior-preserving relocation of legacy source into per-feature src/ dirs during onboarding — split-boundary decisions, the verification stack, and residual-risk caveats
---

# Source Migration Guide

## Overview

Practical companion to [Codebase Source Migration (PF-TSK-091)](../../tasks/00-setup/codebase-source-migration-task.md). The task gives the procedure; this guide covers the judgment-heavy parts: classifying migration actions, deciding split boundaries, running the verification stack, handling language-specific import rewriting, and — most importantly — being honest about what cannot be guaranteed.

## When to Use

Use during framework onboarding, after [Codebase Feature Discovery (PF-TSK-064)](../../tasks/00-setup/codebase-feature-discovery.md) has assigned every source file to a feature, when you need to move that legacy code into the scaffolded `src/<feature>/` directories.

> **🚨 CRITICAL**: The behavioral safety net is only as strong as the existing tests. On thinly-tested legacy code there is **no automated guarantee** that a move preserved untested behavior. Characterization tests (below) are the only mitigation, and they cost real effort. Never present migration of poorly-tested code as risk-free.

## Background

Onboarding scaffolds an empty `src/<feature>/` directory per feature but historically never moved the legacy code into it — leaving empty "husks" while real code sat in pre-framework locations (the source-migration leg of the doc/test/source asymmetry, [PF-EVR-024](../../../../process-framework-central/evaluation-reports/20260528-framework-evaluation-onboarding-process-pf-tsk-059-064-065-066-full-7-d.md) finding F1).

The move is a **behavior-preserving relocation**: file contents don't change meaning, but their *location* and every *reference* to them do. The discipline mirrors [Code Refactoring's standard path](../../tasks/06-maintenance/code-refactoring-standard-path.md) (baseline → characterize → move + rewrite references → diff); the task restates it inline so you don't need PF-TSK-022 open.

## Step-by-Step Instructions

### 1. Classify each migration action

Build the queue from the File Inventory and tag each row by action — this drives how it's verified:

| Action | Shape | Notes |
|--------|-------|-------|
| **Move** | one file → one target | The common case |
| **Split** | one file → multiple features | The file is too big / spans features; divide its functions/classes and rewire *every* caller |
| **Co-locate** | multiple files → one feature dir | Several legacy files land together |

**Expected result:** every File-Inventory file appears in exactly one queue row (Split rows list multiple targets).

### 2. Decide split boundaries (the hard judgment)

A Split is real code surgery, not a move. Deciding *where* a too-big file divides:

- Group functions/classes by the feature that **owns** their behavior (use the File Inventory's per-feature assignment as the starting signal).
- Keep tightly-coupled helpers with the code that calls them most; if a helper is shared, it usually belongs in `shared/`, not duplicated.
- Every split produces 2+ new import sources — confirm the queue row's "refs to update" lists *all* callers before you start.

> Bring split boundaries to the **human partner at the queue checkpoint** (task Step 4). Don't decide them silently.

### 3. Run the verification stack (per item)

Three layers, weakest-to-strongest coverage — all three together are what "behavior preserved" means:

1. **Static resolution** — run the language's import/build/analyze check; an unresolved reference is a hard, coverage-independent failure. The cheapest "did I miss a reference" guarantee.
2. **Local behavioral check (per item)** — **before** the move, run the tests concerning the file to capture its local baseline; **after** the move, re-run the same tests and compare. Use the **project's own test mechanism** — don't assume a framework full-suite runner (a legacy test environment may not be wired to it). An optional final full run (only if the project has one) catches cross-cutting breakage at the end; run it at session boundaries too if you want a tighter window.
3. **Characterization tests** — where coverage is thin, write tests that pin *current* behavior of the unit **before** moving it, so layer 2 has something to protect.

**Expected result:** static check clean + local tests pass for *every* item; the end-of-migration full suite matches the baseline.

### 4. Rewrite references for your language

Look up `directoryStructure.importRewriteTool` in the project's language config:

```jsonc
// python-config.json → directoryStructure
"importRewriteTool": "libcst"   // codemod; rewrites import nodes, preserves formatting
// powershell-config.json → directoryStructure
"importRewriteTool": "manual"   // Import-Module/dot-source/quoted-path refs; LinkWatcher assists
```

The tool is a **hint the agent reads**, never something a framework script executes. If absent or `manual`, edit imports by hand and `grep` for path strings and dynamic/string-based references (which AST tools miss). LinkWatcher updates path strings in monitored file types automatically.

Rewrite **both directions**: **inbound** (callers' imports of the moved file → new path) *and* **outbound** (the moved file's own imports — relative imports break when the file changes directory and must be re-pointed; absolute imports of unmoved modules still resolve).

**Expected result:** all inbound imports (incl. test imports and mocks) and the moved file's own outbound/relative imports resolve to the new location.

## Examples

### Example 1: Simple Move (Python)

`legacy/auth.py` is assigned to feature 1.2; 4 files import it.

1. Characterization check — `test_auth.py` already covers it → skip Step 5.
2. Move → `src/auth/auth.py`.
3. libCST rewrites the 4 callers' `from legacy.auth import ...` → `from src.auth.auth import ...`.
4. `python -c "import src.auth.auth"` resolves; re-run `auth`'s tests and compare to the pre-move local baseline (any final full run is deferred to the exit gate).
5. Update feature 1.2's File Inventory paths and mark the row ✅ **immediately** (per-move, not batched).

### Example 2: Split (n-to-n)

`legacy/utils.py` holds token helpers (feature 1.2) and report formatters (feature 2.1); 9 files reference it.

1. Write characterization tests for both helper groups (thin coverage).
2. Split: token helpers → `src/auth/token.py`; formatters → `src/report/fmt.py`.
3. Rewire all 9 callers to the correct new module.
4. Static check + local tests for both helper groups. The row is ✅ only when **both** pieces are placed, **all 9** callers updated, and the local tests pass.

## Troubleshooting

### Unresolved import after a move

**Symptom:** import/build check fails on a moved file. **Cause:** a caller still references the old path, or a dynamic/string import wasn't rewritten. **Solution:** `grep` the old module path across the tree (including string literals and subprocess/config references); AST tools only catch static import nodes.

### A new test fails that wasn't in the baseline

**Symptom:** suite diff shows a failure absent from the Step 3 baseline. **Cause:** the move changed behavior (often an import-order or shared-state assumption surfaced). **Solution:** this failure is *owned* by the migration — fix it before continuing, or file a discovered bug. Do not dismiss it as "pre-existing."

### Thin coverage — can't tell if behavior is preserved

**Symptom:** the unit has no tests, so the baseline diff proves nothing about it. **Cause:** legacy code without coverage. **Solution:** write characterization tests first (Step 3, layer 3). If that's infeasible for a large surface, surface the residual risk to the human partner and record the decision — don't imply a guarantee.

## Related Resources

- [Codebase Source Migration (PF-TSK-091)](../../tasks/00-setup/codebase-source-migration-task.md) - The task this guide supports
- [Code Refactoring — Standard Path (PF-TSK-022)](../../tasks/06-maintenance/code-refactoring-standard-path.md) - Provenance of the move/verify discipline
- [Codebase Feature Discovery (PF-TSK-064)](../../tasks/00-setup/codebase-feature-discovery.md) - Produces the File Inventory the queue is built from
- [Script Development Quick Reference](../support/script-development-quick-reference.md) - PowerShell execution patterns
