---
id: PF-GDE-073
type: Process Framework
category: Guide
version: 1.2
created: 2026-06-18
updated: 2026-07-22
related_task: PF-TSK-041,PF-TSK-009,PF-TSK-022,PF-TSK-089,PF-TSK-010
description: "Decision guide for classifying a discovered issue (product bug, feature request, framework improvement, or technical debt) and routing it to the correct tracker."
---

# Issue Classification and Routing Guide

## Overview

When you discover a problem — during any task, review, or session — it has to be filed somewhere before it is lost. This guide is the single place that decides **which tracker a discovered issue belongs to**: a product bug, a product feature request, a framework improvement (IMP), or technical debt.

It is the canonical home for that decision. [Bug Triage (PF-TSK-041)](../../tasks/06-maintenance/bug-triage-task.md), [Process Improvement (PF-TSK-009)](../../tasks/support/process-improvement-task.md), [Code Refactoring (PF-TSK-022)](../../tasks/06-maintenance/code-refactoring-task.md), [IMP Triage (PF-TSK-089)](../../tasks/support/imp-triage-task.md), and [Tools Review (PF-TSK-010)](../../tasks/support/tools-review-task.md) point here instead of each carrying their own copy of the rule.

## When to Use

- You discovered a defect, gap, or improvement opportunity mid-task and need to file it.
- A tracked item looks misfiled and you are deciding whether to reclassify it (an IMP that is really a product bug, a bug that is really a framework issue, a TD item that is really a feature request, and so on).
- You are sorting incoming feedback or items by domain.

> This guide decides **where a discovered issue is filed**. It does not decide **which task you run next** — for that, see the [Framework Path vs. Product Path Disambiguation](../../ai-tasks.md#framework-path-vs-product-path-disambiguation) in the task catalog. Both reuse the framework-vs-product boundary, but they answer different questions.

## The Decision

Classify by **what the corrective fix changes**, not the directory the symptom surfaced in. Two steps:

### Step 1 — Does the fix change framework-provided material?

Framework-provided material is anything the process framework owns and rolls out:

- a task, guide, template, or script under `process-framework`, **or**
- the **structure or schema a framework template imposes on a project artifact** — even when the bad output appears in a project file (e.g. a state file is missing a column because the template lacks it; a generated report has the wrong heading because the generator does).

If the fix lands there → **file a framework improvement (IMP)** into the central Process Improvement Tracking (Intake) via [New-ProcessImprovement.ps1](../../scripts/file-creation/support/New-ProcessImprovement.ps1). [IMP Triage (PF-TSK-089)](../../tasks/support/imp-triage-task.md) then sorts it into an Improvement ([PF-TSK-009](../../tasks/support/process-improvement-task.md)), an Extension ([PF-TSK-026](../../tasks/support/framework-extension-task.md)), or a Structural Change ([PF-TSK-014](../../tasks/support/structure-change-task.md)) — you do not pre-decide which.

> **Deferred route — the session's own feedback form.** A framework finding surfaced by the session's own work may instead ride the session feedback form's **Specific Suggestions** list — [Tools Review (PF-TSK-010)](../../tasks/support/tools-review-task.md) drains that list into Intake, so deferring loses nothing and keeps the session's scope freeze intact. File directly (this guide's mechanism) when the finding must exist as a tracked row **before** the next Tools Review cycle: it blocks or affects other sessions, the human partner directs immediate filing, or the owning task's own process files it (e.g. a Process Improvement scope-spillover IMP). Cross-reference every directly-filed IMP in the session's feedback form as `[ALREADY FILED — PF-IMP-NNNN, do not re-file]` so Tools Review does not file it twice.

> **The inverse move — pending work named in prose.** If you write in a routing file (`CLAUDE.md`, `ai-tasks.md`) or a guide that some work is pending, deferred, or owned elsewhere, that work must already exist as a tracked row, and the prose cites its ID. An uncited claim goes stale silently and suppresses the work it describes (PF-IMP-1591).

### Step 2 — Otherwise the fix changes project-specific material; pick by kind

Project-specific material is product source code, the **content** of a project artifact (a state-file value, a project doc's wording), or an artifact created for the project. Choose by the nature of the issue:

| The issue is… | File it as | Tracker / script |
|---|---|---|
| broken existing behavior | **Product bug** | [New-BugReport.ps1](../../scripts/file-creation/06-maintenance/New-BugReport.ps1) → Bug Tracking |
| desired new behavior | **Feature request** | [New-FeatureRequest.ps1](../../scripts/file-creation/01-planning/New-FeatureRequest.ps1) → Feature Request Tracking |
| works, but should be improved later | **Technical debt** | [Update-TechDebt.ps1 -Add](../../scripts/update/Update-TechDebt.ps1) → Technical Debt Tracking |

> A *desired new framework capability* is still filed as an IMP (Step 1) — IMP Triage routes it to a Framework Extension. There is no separate framework feature-request or framework tech-debt tracker; framework betterment of every kind enters through the IMP pipeline.

## Directory Cues — Helpful, Not Decisive

Only two directories settle the question on their own:

- `process-framework` (and root routing files like `CLAUDE.md`, `MEMORY.md`, `ai-tasks.md`) → always framework → IMP.
- product source under `src` → always product → bug / feature / tech-debt by Step 2.

Everything else — `doc`, `test`, `deployment` — is **mixed**, and the path alone decides nothing. Resolve these with Step 1:

- `doc` holds product documentation (`doc/user/…`, product TDDs/APIs) **and** project-local framework state (`doc/state-tracking/…`). A product-doc fix is product; a framework-template/structure fix is an IMP.
- `test` holds product tests **and** framework test infrastructure. A product test exposing a product defect is a bug; a fix to framework-provided test infrastructure is an IMP.
- `deployment` holds project release artifacts **and** framework release tooling. A fix to a framework script or task is an IMP; a fix to a product build/release artifact is product.

## Worked Examples

- **State file under `doc/state-tracking` is wrong.** Missing a column because the framework template omits it → fix the template → **IMP**. Holding a wrong status value a session entered → fix the value in the project → **not an IMP** (a project data correction, not a framework change).
- **A framework script operates on `src`.** A bug in a framework script that reads or writes product source is still an **IMP** — the script is the artifact being fixed; its target is incidental.
- **Product user docs under `doc/user`.** A wrong instruction in a handbook → the fix corrects product documentation → **product bug**, even though the path starts with `doc`.

## Related Resources

- [Framework Path vs. Product Path Disambiguation](../../ai-tasks.md#framework-path-vs-product-path-disambiguation) — the canonical framework/product boundary, used for **task selection**; this guide reuses that boundary for **issue filing**.
- [Documentation Terminology Guide](terminology-guide.md) — the Process-Framework-vs-Product-Documentation conceptual split and ID conventions.
- [Process Improvement Task Reference — Routing](../support/process-improvement-task-reference-guide.md#routing) — section-move mechanics for re-routing an already-filed IMP between tracker sections.
- [Cross-Project Issue Filing Guide](../support/cross-project-issue-filing-guide.md) — filing a product bug or feature request into a *different* registered project.
