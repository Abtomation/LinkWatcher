---
id: PF-GDE-071
type: Process Framework
category: Guide
version: 1.0
created: 2026-06-14
updated: 2026-06-14
related_task: PF-TSK-041,PF-TSK-067
description: How an agent in any registered project files a bug or feature request directly into another registered project by running that project's own creation script, resolved via the central project registry
---

# Cross-Project Issue Filing Guide

## Overview

How an agent in any registered project files a bug or feature request directly into **another** registered project by running that project's own creation script, resolved via the central project registry. No new mechanism is involved — it reuses the per-project creation scripts and the registry that already exist.

## When to Use

Use this when, while working in one project, you discover a **product** bug or feature request that belongs to a *different* registered in-house project — for example:

- An appdev framework session notices a defect in LinkWatcher.
- A TimeTrackingV2 session spots a missing feature in LinkWatcher.

**Scope**: bugs and feature requests only. Framework defects are still filed as IMPs in the central process-improvement tracking, not through this guide — use the [Issue Classification and Routing Guide](../framework/issue-classification-and-routing-guide.md) to tell a product bug/feature from a framework defect. (Cross-project technical-debt filing is intentionally not covered.)

> **🚨 CRITICAL**: Run the **target project's own** copy of the creation script — not the copy in the project you are currently sitting in. The scripts resolve their destination from the script file's own location (`$PSScriptRoot`), so the copy you run decides which project's tracking files get written.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Background](#background)
3. [Step-by-Step Instructions](#step-by-step-instructions)
4. [Examples](#examples)
5. [Troubleshooting](#troubleshooting)
6. [Related Resources](#related-resources)

## Prerequisites

Before you begin, ensure:

- The target project is **registered** in the central `project-registry.json` and **present on the local machine** at its registered `path`.
- You can resolve the central framework path from your current project (every registered project carries a `.framework-central-pointer`; appdev *is* the central host).
- You have enough detail to write a meaningful one-line summary — you do **not** need to fully triage the issue (the target project does that).

## Background

The per-project creation scripts — `New-BugReport.ps1` and `New-FeatureRequest.ps1` — write into the tracking files of **whichever project tree the script file physically lives in**. They call `Get-ProjectRoot`, which walks up from the script's own `$PSScriptRoot` to find the owning `doc/project-config.json`. Two consequences:

- Running **your** project's copy always writes into **your** project — there is no parameter to redirect it elsewhere.
- Running the **target** project's copy writes into the **target** — its ID registry, its `bug-tracking.md` / `feature-request-tracking.md`. This is exactly what cross-project filing needs, and it works with zero script changes.

The only per-project data you need is the target's filesystem path. That lives in the central registry, so the procedure stays the same whether there are 3 registered projects or 50 — the registry grows by one row per project; this guide does not grow at all.

The item you file lands as a **raw, untriaged** entry (`🆕 Needs Triage` for bugs; an unclassified row for feature requests). The target project's own [Bug Triage](../../tasks/06-maintenance/bug-triage-task.md) / [Feature Request Evaluation](../../tasks/01-planning/feature-request-evaluation.md) will triage it later, in that project's context. You are filing a lead, not a verdict.

## Step-by-Step Instructions

### 1. Resolve the target project's path from the registry

Open the central registry and find the entry whose `name` matches the tool:

- **Path**: `process-framework-central/project-registry.json` (the same file `Get-CentralFrameworkPath` resolves — directly under the appdev root when you are in appdev; via your project's `.framework-central-pointer` otherwise).
- Under `projects`, find the object whose `"name"` matches the target tool (e.g. `"LinkWatcher"`) and read its `"path"`.

**Expected result:** an absolute path to the target project, e.g. `C:\Users\ronny\VS_Code\LinkWatcher`.

### 2. File the item using the target project's own script

Invoke the script **inside the target's tree** (substitute `<TARGET_PATH>` from Step 1). Check the target copy's parameters first — its rolled framework version may differ slightly from yours:

```bash
pwsh.exe -ExecutionPolicy Bypass -File "<TARGET_PATH>/process-framework/scripts/file-creation/06-maintenance/New-BugReport.ps1" -?
```

**Bug** → `New-BugReport.ps1` (`06-maintenance`):

```bash
pwsh.exe -ExecutionPolicy Bypass -File "<TARGET_PATH>/process-framework/scripts/file-creation/06-maintenance/New-BugReport.ps1" \
  -Title "<short title>" -Description "<one-line summary, 10-500 chars>" \
  -DiscoveredBy "Development" -Severity "Medium" -Component "<area>" \
  -Evidence "Filed cross-project from <your project> while doing <activity>" -Confirm:\$false
```

**Feature request** → `New-FeatureRequest.ps1` (`01-planning`):

```bash
pwsh.exe -ExecutionPolicy Bypass -File "<TARGET_PATH>/process-framework/scripts/file-creation/01-planning/New-FeatureRequest.ps1" \
  -Source "Cross-project finding (<your project>)" -Description "<one-line summary, 10-500 chars>" \
  -Priority "MEDIUM" -Notes "Filed from <your project> while doing <activity>" -Confirm:\$false
```

**Expected result:** the script reports the assigned ID (`PD-BUG-NNN` / `PD-FRQ-NNN`) and writes the row into the **target** project's tracking file and ID registry.

### 3. File raw and record the cross-project origin

- Do **not** use `-PreTriaged`. You are not in the target's context; let its triage own the verdict.
- `DiscoveredBy` has no "cross-project" value — use the value matching what you were doing (commonly `Development` or `CodeReview`) and record the true origin in `-Evidence` (bug) or `-Notes` (feature request), as the examples above do.
- The new row is now an **uncommitted change in the target project's git repo**. Leave it for a later session in that project (or the human) to review and commit — do not commit another project's working tree from here.

**Expected result:** a clearly-sourced, untriaged item waiting in the target project's intake.

## Examples

### Example 1: appdev session files a LinkWatcher bug

While working an IMP in appdev you notice LinkWatcher's daemon-stop misses instances. LinkWatcher resolves to `C:\Users\ronny\VS_Code\LinkWatcher` in the registry:

```bash
pwsh.exe -ExecutionPolicy Bypass -File "C:/Users/ronny/VS_Code/LinkWatcher/process-framework/scripts/file-creation/06-maintenance/New-BugReport.ps1" \
  -Title "Daemon stop misses running instances" \
  -Description "stop command leaves orphaned daemons; duplicates regenerate on next start" \
  -DiscoveredBy "Development" -Severity "Medium" -Component "Daemon lifecycle" \
  -Evidence "Filed cross-project from appdev (PRJ-000) during framework work" -Confirm:$false
```

**Result:** a `🆕 Needs Triage` bug in LinkWatcher's `bug-tracking.md`, ready for its Bug Triage.

### Example 2: filing a feature request into another project

```bash
pwsh.exe -ExecutionPolicy Bypass -File "C:/Users/ronny/VS_Code/LinkWatcher/process-framework/scripts/file-creation/01-planning/New-FeatureRequest.ps1" \
  -Source "Cross-project finding (TimeTrackingV2)" \
  -Description "Add a --dry-run flag to the validate launcher" \
  -Priority "LOW" -Notes "Noticed while wiring TimeTrackingV2's validate step" -Confirm:$false
```

**Result:** an unclassified row in LinkWatcher's `feature-request-tracking.md`, ready for its Feature Request Evaluation.

## Troubleshooting

### The entry landed in the wrong project (your own, not the target)

**Symptom:** the new row appears in your current project's tracking file.

**Cause:** you ran your own project's copy of the script instead of the target's.

**Solution:** run the copy under `<TARGET_PATH>/process-framework/...`. The destination is decided by the script file's location (`$PSScriptRoot`), not by your working directory. Remove the mis-filed row from your project (and free/ignore the consumed ID per your project's ID-gap policy).

### "Bug tracking file not found" / "Tracking file not found"

**Symptom:** the script errors that the tracking file is missing.

**Cause:** the target path is wrong, or the project predates the tracking file. appdev (PRJ-000) is framework-only and has **no** product bug/feature-request tracking — it is never a filing target.

**Solution:** re-check the `path` in the registry and confirm the project is on disk at that location with a populated `doc/state-tracking/permanent`.

### Can't resolve the registry

**Symptom:** no `.framework-central-pointer`, or it points nowhere.

**Cause:** the project was never reached by a framework Push, or appdev was moved.

**Solution:** in appdev, read `process-framework-central/project-registry.json` directly. In a product project, fix the pointer via a framework rollout. See `Get-CentralFrameworkPath` in `Core.psm1` for the exact resolution rules.

## Related Resources

- [Bug Triage Task](../../tasks/06-maintenance/bug-triage-task.md) — drains bugs filed via this guide (target-project side)
- [Feature Request Evaluation Task](../../tasks/01-planning/feature-request-evaluation.md) — drains feature requests filed via this guide
- [Bug Reporting Guide](../06-maintenance/bug-reporting-guide.md) — standard fields and severity guidance for bug reports
- [Script Development Quick Reference](script-development-quick-reference.md) — PowerShell script-execution patterns for AI agents
