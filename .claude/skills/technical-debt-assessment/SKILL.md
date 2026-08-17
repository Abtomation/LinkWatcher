---
name: technical-debt-assessment
description: >-
  Craft for identifying, prioritizing, and documenting technical debt well — the judgment half of
  the framework's Technical Debt Assessment task (PF-TSK-023). Covers the what-counts-as-debt test,
  per-category identification criteria (references/assessment-criteria.md), the impact/effort
  prioritization frameworks and matrix (references/prioritization.md), and per-item debt-record
  customization — dimension and priority selection, scoping (references/debt-item-creation.md).
  Activated only from the Technical Debt Assessment task's Check-Recommended-Skills step (via
  recommended_skills); the debt-item reference is also consulted inline wherever a PD-TDI record is
  created. Not a refactoring-execution or code-review skill.
user-invocable: false
---

# Technical Debt Assessment Craft

This skill owns the **craft** of a technical-debt assessment — *what to recognize as debt, how to
prioritize it, and how to document each item* so remediation effort lands where it pays. It is the
judgment home for the **Technical Debt Assessment task (PF-TSK-023)**, which owns everything else:
scope definition, checkpoints, the registry automation
(`Update-TechnicalDebtFromAssessment.ps1` / `Update-TechDebt.ps1`), report generation, state-file
updates, and the feedback form.

> **Division of labor.** The task owns process; this skill owns craft. Do **not** run checkpoints,
> create documents, or write the registry from this skill — those stay in the task. This skill
> drives the identification, prioritization, and per-item judgment between the task's checkpoints.

## Reference-don't-bundle: framework scripts this craft uses

This skill bundles **no executables**. The **task** creates and registers artifacts via
`process-framework/scripts/file-creation/cyclical/New-TechnicalDebtAssessment.ps1`,
`New-PrioritizationMatrix.ps1`, `New-DebtItem.ps1`, and
`process-framework/scripts/update/Update-TechDebt.ps1` /
`Update-TechnicalDebtFromAssessment.ps1` — always via the scripts, never hand-authored.

## The core test: debt, not aesthetics

Suboptimal code becomes *debt* only when it meets these criteria — every identified item needs a
clear business justification for remediation:

1. It **impedes future development** or maintenance.
2. It creates **ongoing costs** (performance, security, maintenance, support burden).
3. It was a **conscious trade-off** or has become outdated.
4. Remediation would provide **measurable value**.

Verify each item's description against the actual source code before finalizing — this backs the
task's data-quality rule (descriptions reflect current code, not static-analysis assumptions).

## Reference index (load per task moment)

- **Systematic code analysis / identifying debt** — load
  [references/assessment-criteria.md](references/assessment-criteria.md): per-category
  identification criteria (code quality, architecture, performance, security, testing,
  documentation) with high/medium-priority indicators, the impact/effort evaluation questions, and
  calibration troubleshooting.
- **Prioritization phase** — load
  [references/prioritization.md](references/prioritization.md): the impact and effort scoring
  frameworks (four dimensions each), the priority matrix and quadrants, business-context
  adjustment, and roadmap phasing.
- **Documenting an individual debt item (PD-TDI)** — load
  [references/debt-item-creation.md](references/debt-item-creation.md): dimension (`-Dim`) and
  priority selection, item scoping, detail level, and which template sections are load-bearing.
  Consult this wherever a debt item is created — during this task or from a review that surfaces
  one.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Everything looks high priority | Criteria applied absolutely, not relatively | Force-rank within categories; re-apply the scoring frameworks strictly (see references/prioritization.md) |
| Debt list too large to be actionable | Scope too broad, no filtering | Lead with high-impact items, group related issues into initiatives, cap the cycle's intake |
| Item descriptions later prove wrong | Described from analysis output, not code | Re-read the target code and trace the path before finalizing each item |

(Script path / module-resolution errors: see the
[Script Development Quick Reference](../../../process-framework/guides/support/script-development-quick-reference.md).)
