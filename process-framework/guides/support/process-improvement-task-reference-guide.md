---
id: PF-GDE-068
type: Process Framework
category: Guide
version: 1.0
created: 2026-05-20
updated: 2026-05-20
related_task: PF-TSK-009
description: "Lookup tables and conventions consulted at specific steps of the Process Improvement task: evaluation criteria, routing destinations, risk classification, common stale-description sites, TOOL_DOC_ID convention."
---

# Process Improvement Task Reference

## Document set

Three files cover the Process Improvement task:

- **[Task definition](../../tasks/support/process-improvement-task.md)** — the operative process: 17 steps to execute end-to-end
- **This file** — tables and conventions you look up at specific steps: evaluation criteria, routing destinations, risk classes, common stale-description sites, TOOL_DOC_ID convention
- **[Implementation guide](process-improvement-task-implementation-guide.md)** — worked examples, troubleshooting, and the reasoning behind the gates in this process

Read the task definition end-to-end at session start. Cross to this file at the step that points to it. Read the implementation guide when you want a pattern to imitate or to understand why a gate exists.

## Overview

This reference holds the lookup-shaped content extracted from the Process Improvement task definition during the PF-IMP-880 Diataxis-pilot split. Each section names the task step that consults it.

---

## Evaluation criteria

> **Consulted at**: Task Step 3 (Evaluate the IMP).

First validity, then implementation merit:

| Criterion | Question | Rating |
|-----------|----------|--------|
| **Recurring Value** | Will this benefit multiple future sessions, not just a one-off scenario? | High / Medium / Low |
| **Framework Fit** | Does this align with framework principles and existing patterns? (If the fix requires creating new artifacts rather than modifying existing tooling, route to PF-TSK-026 / PF-TSK-001 instead.) | Good / Marginal / Poor |
| **Maintainability** | Will the change be easy to maintain, or does it add complexity / fragility? | Improves / Neutral / Degrades |
| **Complexity-to-Benefit** | Is the implementation effort proportional to the expected benefit? | Favorable / Balanced / Unfavorable |
| **Minimum Viability** | Could a simpler change (warning-only, doc-only, smaller scope, or *no change at all*) solve the same problem? If yes, prefer the simpler change unless concrete evidence shows it's insufficient. | Yes / No / Not Explored |
| **Root-Cause Targeting** | Does the proposed fix target the underlying defect, or route around it via a flag / option / opt-out / escape hatch? If the latter, what is the underlying defect, and is fixing it in scope? | Root-cause / Symptom-only / N/A |
| **Data-Driven Validation** | Is there data anywhere in the project (feedback DB, review summaries, IMP history, code metrics, git history, test results, etc.) that could validate or invalidate this IMP's premise? If yes, has it been analyzed? | Analyzed / No Data Available |

### Gates

- **Conciseness rule** — When all criteria are favorable (High / Good / Improves / Favorable / Yes-or-No / Root-cause-or-N/A / Analyzed-or-N/A), present a one-line summary at Step 6 (e.g., "Evaluation: all favorable; proceeding with Approach X"). Present the full table only when one or more criteria rate poorly or trigger a gate below.
- **Multiple-poor-rating rule** — If multiple criteria rate poorly (Low / Poor / Degrades / Unfavorable), recommend rejection with rationale.
- **Minimum-viability gate** — If **Minimum Viability** is "Yes" or "Not Explored", the Step 6 checkpoint must explicitly compare the proposed approach against the simpler alternative — present both options to the human partner before committing.
- **Root-cause-vs-symptom gate** — If **Root-Cause Targeting** is "Symptom-only", the Step 6 checkpoint must articulate the underlying defect explicitly and present both the symptom-fix (as the IMP describes) and the root-cause-fix as options for human review. The symptom-fix is sometimes the correct answer (root cause out of scope, or the symptom *is* the actual problem) — but the *distinction* must be surfaced before commitment.
- **Data-driven validation gate** — When **Data-Driven Validation** is "Analyzed", do not proceed to implementation until the analysis is complete. This may require a dedicated multi-session data collection effort (create a temp state file via Step 7). Data sources are unrestricted — feedback DB ratings, review summaries, IMP history, code metrics, git history, test results, or anything else relevant. If the data contradicts the IMP's premise, reject the IMP regardless of intuitive appeal. See [Framework Evaluation](../../tasks/support/framework-evaluation.md) Step 8 for methodology and the IMP-525 precedent.

> Rationale for these gates — minimum-viability, root-cause-vs-symptom, data-driven validation — lives in the [implementation guide](process-improvement-task-implementation-guide.md#explanation).

---

## Routing

> **Consulted at**: Task Step 3 (re-route ill-fitting IMPs), Step 6 (reclassify out-of-framework work), Step 10 (file spillover IMPs).

| Destination | When | Mechanism |
|---|---|---|
| **Section 3 — Extensions** (PF-TSK-026) | New framework capability (new task / new template+script+guide / new workflow) | `Update-ProcessImprovement.ps1 -MoveToSection Extensions -RoutedBy "PF-TSK-009" -Reason "<one-line>"` |
| **Section 4 — Structural Changes** (PF-TSK-014) | Moving files, renaming dirs, reorganizing sections | `Update-ProcessImprovement.ps1 -MoveToSection StructuralChanges -RoutedBy "PF-TSK-009" -Reason "<one-line>"` |
| **Bug Tracking** | Product bug (`src/` defect) misfiled as IMP | [`New-BugReport.ps1`](../../scripts/file-creation/06-maintenance/New-BugReport.ps1) |
| **Feature Request Tracking** | Product feature request misfiled as IMP | [`New-FeatureRequest.ps1`](../../scripts/file-creation/01-planning/New-FeatureRequest.ps1) |
| **Technical Debt Tracking** | Technical / test-infrastructure debt | [`Update-TechDebt.ps1 -Add`](../../scripts/update/Update-TechDebt.ps1) |
| **Scope-spillover IMP** | Mid-execution: planned change overflows into another task's work (PF-TSK-001 / PF-TSK-014 / PF-TSK-026). Complete in-scope parts only; file separate IMP for spillover. | [`New-ProcessImprovement.ps1`](../../scripts/file-creation/support/New-ProcessImprovement.ps1) |

Section moves auto-prepend `[REROUTED YYYY-MM-DD by PF-TSK-009: <reason>]` to Notes. Reclassifications record the new artifact's ID in the IMP rejection note. After re-routing, surface to the human partner — the IMP is no longer this task's responsibility.

**Domain heuristic** (Step 6 reclassification): `process-framework/` and `doc/` = IMP; `src/...` = BUG; `test/` = infrastructure (IMP) or product defect (BUG).

---

## Risk classification

> **Consulted at**: Task Step 10 (Execute changes by risk class).

| Class | Definition |
|---|---|
| **Low-risk** | Typo, wording, link fix, additive callout, single-file edit with no semantic change, formatting / style |
| **Medium-risk** | Behavior changes within one task / script / template, non-trivial logic, multi-file but bounded |
| **High-risk** | Structural change, cross-task or cross-script impact, change to a high-frequency workflow, anything affecting human-facing UX in repeated tasks |

### Per-class execution

- **Low-risk** — implement directly in batch. No per-change checkpoint.
- **Medium-risk** — state the planned change set briefly (one paragraph or bullet list), implement in batch. No per-change checkpoint (the Step 6 approach approval covers it). For framework-script edits, add or update the script's Pester unit test (`<ScriptName>.Tests.ps1` under `appdev/test/automated/unit/framework/<area>/`) inline with the edit and run `pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/Run-Tests.ps1 -Category <area>` (or `-Quick`) — the test pass is the validation evidence. Synthetic harnesses (happy / error / defect-specific cases against real state files) remain a complementary technique for ad-hoc validation when the script's failure mode isn't unit-testable; record pre-fix and post-fix counts in IMP completion notes when used. If the edit affects a user-facing framework workflow (new tracked workflow row or substantively new behavior on an existing one), file a follow-up via [E2E Acceptance Test Case Creation (PF-TSK-069)](../../tasks/03-testing/e2e-acceptance-test-case-creation-task.md); if it changes performance characteristics on a measured surface, route to [Performance Test Creation (PF-TSK-084)](../../tasks/03-testing/performance-test-creation-task.md).
- **High-risk** — per-change loop: for each significant change, (a) present the specific change to be made, (b) **🚨 CHECKPOINT** get explicit approval before implementing, (c) implement the approved change, (d) **🚨 CHECKPOINT** confirm the change meets expectations.

Always state the applied classification at the Step 13 checkpoint so the human can override it.

---

## Common stale-description sites

> **Consulted at**: Task Step 11 (Verify linked documents).

For each file modified in this improvement, grep for its path / filename across the project and read the surrounding paragraph — descriptions, parameter examples, and usage guidance may reference the old behavior and need updating even when the link itself is correct. Sweep these first (non-exhaustive):

- **Script header blocks** — PowerShell `.SYNOPSIS` / `.DESCRIPTION` / `.PARAMETER` / `.EXAMPLE`; Python module docstrings and `--help` / argparse text
- **PF-documentation-map.md** — generated, DO-NOT-EDIT (PF-PRO-037): its one-line descriptions are rendered from each artifact's own `.SYNOPSIS` / `description:` frontmatter / `metadata.description`. Don't hand-edit the map; fix the description at the **source** and rerun `Build-DocumentationMap.ps1` (`-Check` to verify in sync)
- **process-framework-task-registry.md** — per-task automation bullets and the Automation Scripts / Testing Scripts tables describe each script's capabilities
- **README.md files** — `templates/README.md`, directory READMEs, and root README script tables
- **Task definitions** referencing the modified artifact — embedded example invocations and parameter lists

---

## TOOL_DOC_ID convention

> **Consulted at**: Task Step 12 (Log tool change in feedback database).

Canonical `<TOOL_DOC_ID>` form (verify with `feedback_db.py list-tools --filter <substring>`):

- **Task definitions** (file declares `id: PF-TSK-NNN` in frontmatter) → use the task ID: `PF-TSK-NNN` (e.g., `PF-TSK-009`)
- **Everything else** (anything without that frontmatter — templates, guides, scripts, context maps, handbooks, and companion task files like `code-refactoring-lightweight-path.md`) → use the filename: `New-FeedbackForm.ps1`, `framework-evaluation-map.md`, `feature-validation-guide.md`

**⚠️ Unknown tool_doc_id?** The script blocks unknown IDs to prevent silent typos. Before logging, verify the canonical ID:

```bash
python process-framework/scripts/feedback_db.py list-tools --filter <substring>
```

If the tool is genuinely new (first-time registration), add `--new-tool` to acknowledge. For `log-change --batch` (or `Update-ProcessImprovement.ps1 -LogToolChanges`) mixed batches with both known tools and first-time registrations, prefer per-entry `"new_tool": true` in the JSON over the global `--new-tool` flag — it preserves typo detection on the other entries (PF-IMP-866).

---

## Bash `-ValidationNotes` backtick gotcha

> **Consulted at**: Task Step 14 (Update Process Improvement Tracking).

If invoking `Update-ProcessImprovement.ps1` from bash and `-ValidationNotes` contains backtick code spans (e.g., `` `[string]$Param` ``), use **single quotes** around the value — bash command substitution silently truncates backtick segments inside double-quoted strings before pwsh sees them.

---

## Related resources

- [Process Improvement Task Definition](../../tasks/support/process-improvement-task.md) — the canonical process
- [Process Improvement Task Implementation Guide](process-improvement-task-implementation-guide.md) — examples, troubleshooting, gate rationales
- [Process Improvement Context Map](../../visualization/context-maps/support/process-improvement-map.md) — upstream / downstream artifact flow
- [Update-ProcessImprovement.ps1](../../scripts/update/Update-ProcessImprovement.ps1) — driver script for all IMP lifecycle operations
