---
name: source-migration
description: >-
  Craft for behavior-preserving relocation of legacy source into per-feature src/ directories
  during onboarding — the judgment half of the framework's Codebase Source Migration task
  (PF-TSK-091). Covers classifying migration actions (Move / Split / Co-locate), split-boundary
  decisions, the three-layer verification stack (static resolution, per-item local behavioral
  baseline, characterization tests), language-specific import rewriting in both directions, and
  honesty about residual risk on thinly-tested code. Activated only from the Codebase Source
  Migration task's Check-Recommended-Skills step (via recommended_skills); not a refactoring,
  redesign, or feature-discovery skill.
user-invocable: false
---

# Source Migration Craft

This skill owns the **craft** of the framework's **Codebase Source Migration task (PF-TSK-091)**
— the judgment-heavy parts of moving legacy code into the scaffolded `src/<feature>/`
directories: classifying actions, deciding split boundaries, running the verification stack, and
being honest about what cannot be guaranteed. The task owns everything else: the queue, the
per-item procedure, checkpoints, state updates, and the exit gate.

> **Division of labor.** The task owns process; this skill owns craft. Split-boundary decisions
> go to the **human partner at the task's queue checkpoint** — don't decide them silently from
> this skill.

> **🚨 CRITICAL — residual risk**: The behavioral safety net is only as strong as the existing
> tests. On thinly-tested legacy code there is **no automated guarantee** that a move preserved
> untested behavior. Characterization tests are the only mitigation, and they cost real effort.
> Never present migration of poorly-tested code as risk-free — surface the residual risk and
> record the decision.

The move is a **behavior-preserving relocation**: file contents keep their meaning; only their
location and every reference to them change. The discipline mirrors Code Refactoring's standard
path (baseline → characterize → move + rewrite references → diff); the task restates it inline.

## Classify each migration action

Tag each queue row by action — this drives how it's verified:

| Action | Shape | Notes |
|--------|-------|-------|
| **Move** | one file → one target | The common case |
| **Split** | one file → multiple features | The file spans features; divide its functions/classes and rewire *every* caller |
| **Co-locate** | multiple files → one feature dir | Several legacy files land together |

Every File-Inventory file appears in exactly one queue row (Split rows list multiple targets).

## Decide split boundaries (the hard judgment)

A Split is real code surgery, not a move:

- Group functions/classes by the feature that **owns** their behavior (the File Inventory's
  per-feature assignment is the starting signal).
- Keep tightly-coupled helpers with the code that calls them most; a genuinely shared helper
  usually belongs in `shared/`, not duplicated.
- Every split produces 2+ new import sources — confirm the queue row's "refs to update" lists
  *all* callers before starting.

## The verification stack (per item)

Three layers, weakest-to-strongest — all three together are what "behavior preserved" means:

1. **Static resolution** — the language's import/build/analyze check; an unresolved reference is
   a hard, coverage-independent failure. The cheapest "did I miss a reference" guarantee.
2. **Local behavioral check** — *before* the move, run the tests concerning the file to capture
   its local baseline; *after*, re-run the same tests and compare. Use the **project's own test
   mechanism** — don't assume a framework full-suite runner (a legacy test environment may not
   be wired to one). An optional final full run (only if the project has one) catches
   cross-cutting breakage at the end.
3. **Characterization tests** — where coverage is thin, pin *current* behavior of the unit
   **before** moving it, so layer 2 has something to protect.

## Rewrite references for your language

Look up `directoryStructure.importRewriteTool` in the project's language config:

```jsonc
// python-config.json → directoryStructure
"importRewriteTool": "libcst"   // codemod; rewrites import nodes, preserves formatting
// powershell-config.json → directoryStructure
"importRewriteTool": "manual"   // Import-Module/dot-source/quoted-path refs; LinkWatcher assists
```

The tool is a **hint the agent reads**, never something a framework script executes. If absent
or `manual`, edit imports by hand and `grep` for path strings and dynamic/string-based
references (which AST tools miss). LinkWatcher updates path strings in monitored file types
automatically.

Rewrite **both directions**: **inbound** (callers' imports of the moved file — including test
imports and mock paths) *and* **outbound** (the moved file's own imports — relative imports
break when the file changes directory; absolute imports of unmoved modules still resolve).

## Worked examples

**Simple Move (Python)** — `legacy/auth.py` assigned to feature 1.2; 4 files import it:
existing `test_auth.py` covers it → no characterization needed; move to `src/auth/auth.py`;
libCST rewrites the 4 callers; `python -c "import src.auth.auth"` resolves; re-run auth's tests
against the pre-move baseline; update the File Inventory and mark the row ✅ **immediately**
(per-move, not batched).

**Split (n-to-n)** — `legacy/utils.py` holds token helpers (feature 1.2) and report formatters
(feature 2.1); 9 files reference it: characterization tests for both helper groups first (thin
coverage); split to `src/auth/token.py` + `src/report/fmt.py`; rewire all 9 callers; the row is
✅ only when **both** pieces are placed, **all 9** callers updated, and the local tests pass.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Unresolved import after a move | A caller still references the old path, or a dynamic/string import wasn't rewritten | `grep` the old module path across the tree — including string literals and subprocess/config references; AST tools only catch static import nodes |
| A new test failure absent from the item's baseline | The move changed behavior (often an import-order or shared-state assumption) | The failure is *owned* by the migration — fix it or file a discovered bug; never dismiss it as "pre-existing" |
| Thin coverage — the baseline diff proves nothing | Legacy code without tests | Write characterization tests first; if infeasible for a large surface, surface the residual risk to the human partner and record the decision — don't imply a guarantee |
