---
id: PF-PRO-028
type: Process Framework
category: Proposal
version: 1.3
created: 2026-04-27
updated: 2026-04-27
extension_name: Script Self-Verification
extension_description: Adds reusable script self-verification infrastructure: Assert-LineInFile/Test-LineInFile helpers for immediate post-write verification (catches known silent-success failures), and a soak-verification helper that requires explicit agent acknowledgment over 5 successful invocations of newly-registered or hash-changed scripts (catches unknown failure modes). PowerShell-only initially.
extension_scope: New helper functions in FileOperations.psm1 (Assert-LineInFile, Test-LineInFile); new sub-module ExecutionVerification.psm1 (Register-SoakScript, Confirm-SoakInvocation, Test-ScriptInSoak, Get-SoakStatus); new shareable state file process-framework/state-tracking/permanent/script-soak-tracking.md; modifications to PF-TSK-026 and PF-TSK-001 finalization steps (registration hooks for any task that creates new scripts); pilot adoption in New-IntegrationNarrative.ps1 and New-Handbook.ps1.
related_imp: PF-IMP-586
---

# Script Self-Verification — Framework Extension Concept

## Document Metadata
| Metadata | Value |
|----------|-------|
| Document Type | Framework Extension Concept |
| Created Date | 2026-04-27 |
| Status | Awaiting Human Review (revision 1.3 (concept-stage final, ready for Step 4 impact analysis)) |
| Extension Name | Script Self-Verification |
| Origin | [PF-IMP-586](../../state-tracking/permanent/process-improvement-tracking.md) (delegated from narrow PF-TSK-083 fix to reusable framework infrastructure) |
| Author | AI Agent & Human Partner |

---

## 🔀 Extension Type

**Selected Type**: **Hybrid**

**Why Hybrid**: The extension creates new artifacts (helper functions, a new sub-module, a new permanent state file) AND modifies existing artifacts ([PF-TSK-026](../../../process-framework/tasks/support/framework-extension-task.md) and [PF-TSK-001](../../../process-framework/tasks/support/new-task-creation-process.md) finalization steps — both tasks can create new scripts and so both need the registration hook — plus pilot integration into [`New-IntegrationNarrative.ps1`](../../../process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1) and [`New-Handbook.ps1`](../../../process-framework/scripts/file-creation/07-deployment/New-Handbook.ps1)).

---

## 🎯 Purpose & Context

**Brief Description**: Provides reusable infrastructure that closes the silent-success failure gap in PowerShell scripts. Two complementary helpers: (1) an immediate post-write assertion helper that scripts call after any edit site to catch *known* failure modes deterministically, and (2) a soak-verification helper that requires explicit agent acknowledgment over the first 5 successful invocations of a newly-registered or hash-changed script to catch *unknown* failure modes. Reset-on-code-change is automatic via SHA256 content hashing.

### Extension Overview

The framework currently has **no mechanism that verifies a script's claimed write actually produced the expected on-disk change at the moment of writing**. This gap has produced four duplicate tech-debt filings against the same root cause ([`New-IntegrationNarrative.ps1`](../../../process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1) doc-map silent-success: TD221, TD222, TD225, TD230) and was the most prominent theme ("Theme 4: Silent-success failure modes") in [tools-review-20260422-111222.md](../../feedback/reviews/tools-review-20260422-111222.md).

The extension adds three components:

1. **`Assert-LineInFile` / `Test-LineInFile` helpers** — added to the existing [`FileOperations.psm1`](../../../process-framework/scripts/Common-ScriptHelpers/FileOperations.psm1) sub-module. After a script writes to a file (any number of edits — single-file or multi-file), it calls `Assert-LineInFile -Path X -Pattern Y` to verify the expected line exists. If the assertion fails, the script throws a clear error rather than emitting a buried warning. Pure function; no state.

2. **[`ExecutionVerification.psm1`](../../../process-framework/scripts/Common-ScriptHelpers/ExecutionVerification.psm1) — new sub-module** with `Register-SoakScript`, `Confirm-SoakInvocation`, `Test-ScriptInSoak`, and `Get-SoakStatus`. Newly-created scripts are registered with a soak counter fixed at 5. On each invocation while in soak (and not in `-WhatIf` mode), the script must call `Confirm-SoakInvocation -Outcome success|failure` after the agent has explicitly verified the run produced the expected outcome. Only `success` decrements the counter; `failure` resets the counter back to 5. **Hash-based auto-reset**: any change to the registered script's content (detected on next invocation via SHA256) automatically resets the counter — no manual ceremony required. **`-WhatIf` runs are bypassed entirely** — no prompt, no decrement, no reset.

3. **[`script-soak-tracking.md`](../../../process-framework/state-tracking/permanent/script-soak-tracking.md) — new shareable state file** in `process-framework/state-tracking/permanent/` (NOT in `process-framework-local`, since scripts are shared across projects, so soak state should be too). One row per registered script: Script ID (relative path), Content Hash, Current Counter, Status, Last Invocation Date, Last Outcome, Notes.

### Key Distinction from Existing Framework Components

| Existing Component | Purpose | Scope |
|-------------------|---------|-------|
| [`Validate-StateTracking.ps1`](../../../process-framework/scripts/validation/Validate-StateTracking.ps1) | Periodic, post-hoc validation across 15 surfaces | Catches drift days/weeks after introduction; not at write-time |
| Inline `# Testing Checklist` comments at end of scripts | Advisory checklist for developers | Not enforced at runtime; relies on memory/discipline |
| `Add-DocumentationMapEntry` returning `$false` | Returns bool on section-not-found; caller emits warning | Warning text buried under success banner; agent misses it |
| Pester / pytest tests | Pre-merge regression catching | Catch logic bugs in test fixtures, not real-world script invocations |
| **Script Self-Verification** *(this extension)* | **Catch silent-success failures at the exact moment they occur (assertion) and force re-verification of new/changed scripts (soak)** | **Runtime, in-script, deterministic for known failure modes; explicit acknowledgment for unknown ones; PS-only initially** |

## 🔍 When to Use This Extension

This framework extension should be used when:

- **A script edits a file with a deterministic post-condition** (any number of files, single or multi). The script writes assertions immediately after each edit so a regex/section/path drift is caught at the moment of the bad write — not later, not by a periodic validator.
- **A script is newly created** (via [PF-TSK-026](../../../process-framework/tasks/support/framework-extension-task.md) or [PF-TSK-001](../../../process-framework/tasks/support/new-task-creation-process.md) Session 2). First 5 successful invocations require explicit agent acknowledgment. Discovers unknown failure modes that no assertion was written for.
- **A script is reworked (any code change)**: hash-based auto-detection resets the soak counter on next invocation. The agent re-verifies the changed script over its next 5 successful runs. **No manual reset call needed.**
- **A script is found to silently fail and needs verification armor**: the fix-author adds `Assert-LineInFile` calls inline; hash change auto-resets the soak counter on next run.

### Example Use Cases

- **[`New-IntegrationNarrative.ps1`](../../../process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1) doc-map append**: after `Add-DocumentationMapEntry`, call `Assert-LineInFile -Path doc/PD-documentation-map.md -Pattern "$documentId.*$customFileName"`. Failure throws — agent fixes the regex bug at the moment it ships, not 4 sessions later via duplicate TD filings.
- **[`New-IntegrationNarrative.ps1`](../../../process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1) workflow-tracking row update**: after `Set-Content`, call `Assert-LineInFile -Path doc/state-tracking/permanent/user-workflow-tracking.md -Pattern "\| $WorkflowId \|.*$documentId"`. Catches "row index not found" or "Integration Doc column missing" silent-failure paths.
- **A new `New-FooReport.ps1` script created via [PF-TSK-026](../../../process-framework/tasks/support/framework-extension-task.md) or [PF-TSK-001](../../../process-framework/tasks/support/new-task-creation-process.md)**: as part of finalization, agent calls `Register-SoakScript -ScriptId "process-framework/scripts/file-creation/...New-FooReport.ps1"`. First 5 successful real invocations require `Confirm-SoakInvocation` with explicit verification.
- **Bug fix to an existing soaking script**: agent edits the script body (any reason). On next invocation, `Test-ScriptInSoak` re-hashes, sees the diff, automatically resets counter to 5. No manual ceremony.

## 🔎 Existing Project Precedents

| Precedent | Where It Lives | What It Does | How It Relates to This Extension |
|-----------|---------------|--------------|----------------------------------|
| `Add-DocumentationMapEntry` returns `$false` on section-not-found | [`Common-ScriptHelpers/DocumentManagement.psm1`](../../../process-framework/scripts/Common-ScriptHelpers/DocumentManagement.psm1) lines 824–950 | Caller appends a textual warning ("...Section X not found — add entry manually"). | **Gap**: warning text gets buried in the post-success banner. Agent reads "✅ Created with ID: PD-INT-XXX" header and misses the warning. Extension closes this by making the caller fail loudly via `Assert-LineInFile`. |
| Inline `# Testing Checklist` comments at end of every major creation script | E.g., [`New-IntegrationNarrative.ps1`](../../../process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1) lines 244–264 | Lists 5–10 manual verification items as a `<#...#>` block. | **Gap**: advisory only — not enforced at runtime. Extension converts the deterministic checklist items (e.g., "doc-map updated") into runtime assertions; the non-deterministic items (e.g., "narrative reads naturally") remain advisory. |
| [`Validate-StateTracking.ps1`](../../../process-framework/scripts/validation/Validate-StateTracking.ps1) 15-surface periodic validation | `scripts/validation/` | Validates state files across 15 surfaces (cross-references, ID counters, dimension consistency, etc.). | **Complement**: catches drift days/weeks later. Extension catches at write-time so a failing surface never accumulates. The two operate at different time horizons. |
| `Update-FeatureTrackingStatus` idempotent row update pattern | [`DocumentTracking.psm1`](../../../process-framework/scripts/Common-ScriptHelpers/DocumentTracking.psm1) | Reads file, updates one row, writes back. Idempotent — no-op if already in target state. | **Reuse**: `Register-SoakScript` adopts the same Get-Content/Test/Set-Content guard pattern for `script-soak-tracking.md`. |
| Process-Improvement-Tracking Update History schema | [`process-improvement-tracking.md`](../../state-tracking/permanent/process-improvement-tracking.md) | Append-only history table with `Date | Action | Actor` columns. | **Reuse**: same schema for soak invocation log within `script-soak-tracking.md`. |
| Hash-based file change detection (none currently in framework) | — | — | **New pattern**: extension introduces SHA256 content-hash comparison for auto-reset. No existing precedent in the framework, but `Get-FileHash -Algorithm SHA256` is a single-line PowerShell built-in. |
| Script ID system (does not exist in [PF-id-registry.json](../../../process-framework/PF-id-registry.json)) | — | — | **Concept doc records this as Open Design Tension**. Default approach (Option α): use script relative path from project root as the soak ID. Alternative (Option β): introduce a new `PF-SCR` prefix and assign IDs to scripts. |

**Key takeaways**:
- The framework has **no write-time assertion infrastructure** — every existing self-check is either advisory comment or post-hoc periodic validation.
- The "warning buried in success banner" failure mode is **structural** (4 duplicate TD filings) — fixing it requires moving from textual warnings to throw-based failures.
- The **soak counter idea has no precedent** but reuses existing patterns (idempotent state file updates, append-only history) for its persistence layer.
- Reset-on-code-change via content hash is **new but small**: PowerShell `Get-FileHash -Algorithm SHA256` does the work in one line.
- **Scripts have no ID registry** — this concept defaults to relative-path-as-ID (Option α) to avoid scope expansion.

## 🔌 Interfaces to Existing Framework

### Task Interfaces

| Existing Task | Interface Type | Description |
|--------------|----------------|-------------|
| [PF-TSK-026 (Framework Extension)](../../../process-framework/tasks/support/framework-extension-task.md) | **Modified by extension** (registration hook) | Finalization step adds: "For each new script created by this extension, call `Register-SoakScript -ScriptId X` to register the script for soak verification." |
| [PF-TSK-001 (New Task Creation Process)](../../../process-framework/tasks/support/new-task-creation-process.md) | **Modified by extension** (registration hook) | Finalization step adds: "For each new document creation script generated by Session 2 (Document Creation Infrastructure), call `Register-SoakScript -ScriptId X` to register the script for soak verification." Also affects the Lightweight-mode checklist if the lightweight path ever creates a script (it doesn't currently, but the task definition documents the pattern for consistency). |
| [PF-TSK-083 (Integration Narrative Creation)](../../../process-framework/tasks/02-design/integration-narrative-creation.md) | Pilot adopter (script update only) | Original IMP-586 trigger: [`New-IntegrationNarrative.ps1`](../../../process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1) is the first script to adopt `Assert-LineInFile` and the soak helper. No modification to the task definition itself. |
| [PF-TSK-081 (User Documentation Creation)](../../../process-framework/tasks/07-deployment/user-documentation-creation.md) | Pilot adopter (script update only) | [`New-Handbook.ps1`](../../../process-framework/scripts/file-creation/07-deployment/New-Handbook.ps1) is the second pilot — same multi-file pattern (auto-updates PD-documentation-map.md). No modification to the task definition itself. |
| [PF-TSK-009 (Process Improvement)](../../../process-framework/tasks/support/process-improvement-task.md) | **Out of scope** (handled automatically) | When an IMP modifies a script body, hash-based auto-reset triggers on next invocation — no task-definition change required. |

### State File Interfaces

| State File | Read / Write / Both | What the Extension Uses or Updates |
|-----------|---------------------|-----------------------------------|
| [`process-framework/state-tracking/permanent/script-soak-tracking.md`](../../../process-framework/state-tracking/permanent/script-soak-tracking.md) *(NEW, this extension; shareable across projects)* | Both | Created and maintained by `Register-SoakScript` / `Confirm-SoakInvocation` / hash-based auto-reset |

No other state files are modified.

### Artifact Interfaces

| Existing Artifact | Relationship | Description |
|------------------|--------------|-------------|
| [`Common-ScriptHelpers.psm1`](../../../process-framework/scripts/Common-ScriptHelpers.psm1) | Updated by extension | Add `ExecutionVerification.psm1` to the `$SubModules` array (line 44) so the new sub-module loads. Update fallback `$AllExportedFunctions` list (line 88+) with new function names. |
| [`Common-ScriptHelpers/FileOperations.psm1`](../../../process-framework/scripts/Common-ScriptHelpers/FileOperations.psm1) | Updated by extension | Add `Assert-LineInFile` and `Test-LineInFile` functions; export them. |
| [`Common-ScriptHelpers/ExecutionVerification.psm1`](../../../process-framework/scripts/Common-ScriptHelpers/ExecutionVerification.psm1) | Created by extension | New sub-module containing soak helpers. |
| [`PF-documentation-map.md`](../../../process-framework/PF-documentation-map.md) | Updated by extension | Add entries for new sub-module under State Update Scripts (or appropriate section), and the new state file under State Tracking Files. |
| [`process-framework/state-tracking/permanent/script-soak-tracking.md`](../../../process-framework/state-tracking/permanent/script-soak-tracking.md) | Created by extension | New shareable permanent state file. |
| [`New-IntegrationNarrative.ps1`](../../../process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1) (pilot adopter #1) | Updated by extension | Add `Assert-LineInFile` calls after `Add-DocumentationMapEntry` and after the workflow-tracking row Set-Content. Add `Test-ScriptInSoak` at start, `Confirm-SoakInvocation` near end. |
| [`New-Handbook.ps1`](../../../process-framework/scripts/file-creation/07-deployment/New-Handbook.ps1) (pilot adopter #2) | Updated by extension | Add `Assert-LineInFile` calls at edit sites with deterministic post-conditions. Add soak hooks. |
| [`PF-TSK-026 task definition`](../../../process-framework/tasks/support/framework-extension-task.md) | Updated by extension | Add finalization sub-step: "For each new script created, run `Register-SoakScript`." |
| [`PF-TSK-001 task definition`](../../../process-framework/tasks/support/new-task-creation-process.md) | Updated by extension | Add finalization sub-step in Session 2 (Document Creation Infrastructure): "For each new document creation script created, run `Register-SoakScript`." |

## 🏗️ Core Process Overview

This extension is a piece of **infrastructure**, not a workflow. Its "process" describes the end-to-end behavior the infrastructure produces.

### Phase 1: Library Helper Available

1. **Script imports `Common-ScriptHelpers`** — already standard in all PS scripts; no change.
2. **After any edit with a deterministic post-condition**, the script calls `Assert-LineInFile -Path X -Pattern Y` to verify the expected on-disk change exists. Single-file or multi-file scripts use this identically.
3. **On assertion failure**, the helper throws a descriptive error: `"Assertion failed: pattern '$Pattern' not found in '$Path' (expected ≥ $MinOccurrences match(es), found 0). Context: $Context."` Script exits non-zero.
4. **On assertion success**, no output (the script's existing success banner stands).

### Phase 2: Soak Lifecycle

5. **New script created** ([PF-TSK-026](../../../process-framework/tasks/support/framework-extension-task.md) finalization, or [PF-TSK-001](../../../process-framework/tasks/support/new-task-creation-process.md) Session 2 finalization) — agent runs `Register-SoakScript -ScriptId <relative-path> -ScriptPath <absolute-path>`. **No counter parameter** — fixed at 5.
6. **Soak entry written to [`script-soak-tracking.md`](../../../process-framework/state-tracking/permanent/script-soak-tracking.md)** with current SHA256 content hash, counter = 5, status = "Active Soak".
7. **Script invoked subsequently** — script's first action is `Test-ScriptInSoak -ScriptId X -ScriptPath Y`:
   - **If `-WhatIf` mode is active** → returns `$false` immediately (bypass — WhatIf does not count).
   - If file hash differs from registered hash → counter reset to 5, hash updated, log entry added.
   - Returns `$true` if counter > 0 (and not WhatIf); `$false` otherwise.
8. **If in soak (and not WhatIf)**: script proceeds normally, then at the end calls `Confirm-SoakInvocation -ScriptId X -Outcome <success|failure> [-Notes Z]`.
   - **Outcome = success** → counter decrements by 1; if counter hits 0, status flips to "Soak Complete".
   - **Outcome = failure** → counter resets to 5, status remains "Active Soak"; failure logged with notes.
   - **WhatIf** → `Confirm-SoakInvocation` is a no-op (`$WhatIfPreference` check) — returns immediately, no state file write.
9. **Agent must verify the run before answering `success`** — re-read the affected file(s), confirm the expected change is present. The verification is the agent's responsibility; the helper just tracks the answer.

### Phase 3: Reset-on-Code-Change (Automatic)

10. **Script body changed** (any reason — bug fix, refactor, feature add, IMP via PF-TSK-009) — no special action needed.
11. **Next invocation** — `Test-ScriptInSoak` re-hashes the file, sees a difference, automatically resets counter to 5 and updates the registered hash. Soak resumes for next 5 successful invocations.
12. **No human/agent intervention required** — the only manual reset triggers are explicit `failure` outcomes from `Confirm-SoakInvocation`.

### Phase 4: Soak Complete

13. **Counter reaches 0 with no failures (5 successful invocations)** — status flips to "Soak Complete". Subsequent invocations skip the prompt; only `Assert-LineInFile` keeps protecting against known failure modes.
14. **Human inspects `Get-SoakStatus`** periodically (e.g., during Tools Review) to spot scripts stuck in soak (counter not decrementing — agent forgetting to call `Confirm-SoakInvocation`).

## 🔗 Integration with Task-Based Development Principles

### Adherence to Core Principles
- **Task Granularity**: Implementation split across 4 sessions, each independently completable and useful (Session 1's helpers can ship without Sessions 2–4).
- **State Tracking**: New shareable permanent state file ([`script-soak-tracking.md`](../../../process-framework/state-tracking/permanent/script-soak-tracking.md)) plus a multi-session temp state file for implementation continuity.
- **Artifact Management**: Two new code artifacts (one helper extension to existing module, one new sub-module) + one new state file. Clear ownership: `ExecutionVerification.psm1` owns the soak state; scripts own their own assertions.
- **Task Handover**: Multi-session implementation tracked via [`New-TempTaskState.ps1 -Variant FrameworkExtension`](../../../process-framework/scripts/file-creation/support/New-TempTaskState.ps1).

### Framework Evolution Approach
- **Incremental Extension**: Helpers can be adopted by scripts one at a time. No big-bang migration. Existing scripts that don't adopt the helpers continue working unchanged.
- **Consistency Maintenance**: Helpers live in the existing [`Common-ScriptHelpers`](../../../process-framework/scripts/Common-ScriptHelpers.psm1) facade — same import pattern, same approved-verb naming, same UTF-8 encoding defaults.
- **Integration Focus**: Designed to coexist with [`Validate-StateTracking.ps1`](../../../process-framework/scripts/validation/Validate-StateTracking.ps1) (post-hoc) and Pester tests (pre-merge). Different time horizons, complementary safety nets.
- **Documentation Alignment**: Concept doc, task definition update, and PF-documentation-map entries follow standard framework patterns.

## 📊 Detailed Workflow & Artifact Management

### Workflow Definition

#### Input Requirements
- **Script source code** — for hash computation and (eventually) the in-script `Assert-LineInFile` calls authored by the developer.
- **Target file path + pattern** — supplied to `Assert-LineInFile` per call.
- **Outcome judgment** — supplied by agent to `Confirm-SoakInvocation` after verifying the run.

#### Process Flow

```
Script Edit Site                                        Soak Site
================                                        =========

Set-Content -Path X -Value Y                            Test-ScriptInSoak -ScriptId Z -ScriptPath Z'
       ↓                                                       ↓
Assert-LineInFile -Path X -Pattern P                    [WhatIf?] -- yes --> return $false (bypass)
       ↓                                                       ↓ no
[match found?] -- no --> throw                          [hash diff?] -- yes --> Reset-Counter to 5
       |                                                       ↓
       yes                                              [counter > 0?] -- yes -->
       ↓                                                       ↓
return (success path)                                   run script logic
                                                                ↓
                                                        Confirm-SoakInvocation -Outcome <success|failure>
                                                                ↓
                                                        update script-soak-tracking.md
                                                        (no-op in WhatIf)
```

### Artifact Dependency Map

#### New Artifacts Created

| Artifact Type | Name | Directory | Purpose | Serves as Input For |
|---------------|------|-----------|---------|-------------------|
| **PowerShell module** | [`ExecutionVerification.psm1`](../../../process-framework/scripts/Common-ScriptHelpers/ExecutionVerification.psm1) | `process-framework/scripts/Common-ScriptHelpers/` | Sub-module containing soak helpers | Loaded by `Common-ScriptHelpers.psm1` facade; used by every script that registers for soak |
| **PowerShell function** (in existing module) | `Assert-LineInFile` | [`Common-ScriptHelpers/FileOperations.psm1`](../../../process-framework/scripts/Common-ScriptHelpers/FileOperations.psm1) | Throws on missing pattern | Called by every script that does an edit with a deterministic post-condition |
| **PowerShell function** (in existing module) | `Test-LineInFile` | [`Common-ScriptHelpers/FileOperations.psm1`](../../../process-framework/scripts/Common-ScriptHelpers/FileOperations.psm1) | Returns bool, non-throwing variant | Called by scripts wanting conditional flow |
| **Shareable permanent state file** | [`script-soak-tracking.md`](../../../process-framework/state-tracking/permanent/script-soak-tracking.md) | `process-framework/state-tracking/permanent/` | Tracks per-script soak counters and history; shareable across projects since scripts are shared | Read by `Test-ScriptInSoak`; written by `Register-SoakScript`/`Confirm-SoakInvocation` |
| **Temporary state file** | `temp-script-self-verification-state.md` | `process-framework-local/state-tracking/temporary/` | Multi-session implementation tracker | Used by implementation sessions |

#### Dependencies on Existing Artifacts
| Required Artifact | Source | Usage |
|------------------|--------|-------|
| [`Common-ScriptHelpers.psm1`](../../../process-framework/scripts/Common-ScriptHelpers.psm1) (facade) | Project | Updated to load `ExecutionVerification.psm1`; updated export list |
| [`FileOperations.psm1`](../../../process-framework/scripts/Common-ScriptHelpers/FileOperations.psm1) (sub-module) | Project | Receives new `Assert-LineInFile` and `Test-LineInFile` functions |
| [`New-IntegrationNarrative.ps1`](../../../process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1) (pilot #1) | Project | Receives `Assert-LineInFile` and soak hook calls |
| [`New-Handbook.ps1`](../../../process-framework/scripts/file-creation/07-deployment/New-Handbook.ps1) (pilot #2) | Project | Receives `Assert-LineInFile` and soak hook calls |
| [`PF-TSK-026 task definition`](../../../process-framework/tasks/support/framework-extension-task.md) | Project | Receives new finalization sub-step text |
| [`PF-documentation-map.md`](../../../process-framework/PF-documentation-map.md) | Project | Receives entries for new artifacts |

### State Tracking Integration Strategy

#### New Permanent State Files Required
- **[`process-framework/state-tracking/permanent/script-soak-tracking.md`](../../../process-framework/state-tracking/permanent/script-soak-tracking.md)**: Tracks every script registered for soak verification. **Shareable across projects** (lives in `process-framework/`, not `process-framework-local/`). Schema:

```markdown
| Script ID | Content Hash | Current Counter | Status | Last Invocation | Last Outcome | Notes |
|-----------|--------------|-----------------|--------|-----------------|--------------|-------|
| process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1 | a1b2c3... | 3 | Active Soak | 2026-04-27 | success | First-pilot adopter |
```

> **Note on Script ID column**: Script ID = relative path from project root (Option α). Stable across projects since scripts are at the same path everywhere. No new ID registry needed. If introducing a `PF-SCR` prefix is desired, that's a separate IMP — flagged in Open Design Tensions below.

Plus an Update History section (append-only), same schema as [`process-improvement-tracking.md`](../../state-tracking/permanent/process-improvement-tracking.md):

```markdown
## Update History

| Date | Action | Actor |
|------|--------|-------|
| 2026-04-27 | Registered process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1 | AI Agent (PF-TSK-026) |
| 2026-04-27 | Confirmed success invocation; counter 5 → 4 | AI Agent (PF-TSK-083) |
| 2026-04-28 | Hash mismatch detected; auto-reset counter to 5 | Confirm-SoakInvocation (auto) |
```

#### Updates to Existing State Files
- None directly. The extension is read-only against existing state files.

#### State Update Triggers
- **`Register-SoakScript` invoked** → adds row to `script-soak-tracking.md`, writes initial hash and counter=5.
- **`Test-ScriptInSoak` detects hash mismatch** → resets counter to 5, updates hash, logs Update History entry.
- **`Confirm-SoakInvocation` called with success** → decrements counter, logs entry.
- **`Confirm-SoakInvocation` called with failure** → resets counter to 5, logs entry with notes.
- **`-WhatIf` mode active** → all write operations are no-ops.

## 🔄 Modification-Focused Sections

### State Tracking Audit

| State File | Current Purpose | Modification Needed | Change Type |
|-----------|-----------------|---------------------|-------------|
| [`script-soak-tracking.md`](../../../process-framework/state-tracking/permanent/script-soak-tracking.md) *(NEW, shareable)* | N/A | Created from scratch in shared `process-framework/` | New file |

No modifications to existing state files.

**Cross-reference impact**: None — the new state file has no parsers or scripts depending on it yet.

### Guide Update Inventory

| File to Update | References To | Update Needed |
|---------------|---------------|---------------|
| [`process-framework/tasks/support/framework-extension-task.md`](../../../process-framework/tasks/support/framework-extension-task.md) (PF-TSK-026) | Existing finalization steps | Add sub-step: "For each new script created by this extension, run `Register-SoakScript -ScriptId <relative-path>`." |
| [`process-framework/tasks/support/new-task-creation-process.md`](../../../process-framework/tasks/support/new-task-creation-process.md) (PF-TSK-001) | Session 2 (Document Creation Infrastructure) finalization | Add sub-step: "For each new document creation script created via [`New-Task.ps1`](../../../process-framework/scripts/file-creation/support/New-Task.ps1) Session 2 flow, run `Register-SoakScript -ScriptId <relative-path>`." Update Full Mode Task Completion Checklist Session 2 verification block accordingly. |
| [`process-framework/PF-documentation-map.md`](../../../process-framework/PF-documentation-map.md) | All process framework artifacts | Add entries for new sub-module ([`ExecutionVerification.psm1`](../../../process-framework/scripts/Common-ScriptHelpers/ExecutionVerification.psm1)) and new state file ([`script-soak-tracking.md`](../../../process-framework/state-tracking/permanent/script-soak-tracking.md)). |
| [`process-framework/scripts/Common-ScriptHelpers.psm1`](../../../process-framework/scripts/Common-ScriptHelpers.psm1) | `$SubModules` array, `$AllExportedFunctions` list | Add `ExecutionVerification.psm1` to `$SubModules`; add new function names to fallback export list. |
| [`process-framework/scripts/Common-ScriptHelpers/FileOperations.psm1`](../../../process-framework/scripts/Common-ScriptHelpers/FileOperations.psm1) | Existing function exports | Add `Assert-LineInFile` and `Test-LineInFile` functions and exports. |
| [`process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1`](../../../process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1) (pilot adopter #1) | Edit sites | Add `Assert-LineInFile` calls after `Add-DocumentationMapEntry` and after the workflow-tracking `Set-Content`. Call `Test-ScriptInSoak` at start and `Confirm-SoakInvocation` at end. |
| [`process-framework/scripts/file-creation/07-deployment/New-Handbook.ps1`](../../../process-framework/scripts/file-creation/07-deployment/New-Handbook.ps1) (pilot adopter #2) | Edit sites | Same pattern: assertions + soak hooks. |
| [`process-framework-local/state-tracking/permanent/process-improvement-tracking.md`](../../state-tracking/permanent/process-improvement-tracking.md) | PF-IMP-586 row | Update via [`Update-ProcessImprovement.ps1`](../../../process-framework/scripts/update/Update-ProcessImprovement.ps1) to "Completed" upon implementation finalization. |
| [`process-framework/infrastructure/process-framework-task-registry.md`](../../../process-framework/infrastructure/process-framework-task-registry.md) | PF-TSK-026 entry | Update to reflect new finalization output (`script-soak-tracking.md`). |

**Discovery method**:
- `grep` for `Add-DocumentationMapEntry` — found 1 caller ([`New-IntegrationNarrative.ps1`](../../../process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1)); [`New-Handbook.ps1`](../../../process-framework/scripts/file-creation/07-deployment/New-Handbook.ps1) likely has analogous pattern (confirmed as pilot #2).
- `grep` for `Set-Content -Path` in scripts — 76 occurrences across 42 files. Most are not currently in scope; pilot armoring targets the two scripts with documented silent-success failure modes.
- Manual review of [`Common-ScriptHelpers.psm1`](../../../process-framework/scripts/Common-ScriptHelpers.psm1) facade structure to identify export-list integration points.
- Manual review of [`PF-id-registry.json`](../../../process-framework/PF-id-registry.json) confirmed no `PF-SCR` prefix exists; relative-path-as-ID is the lowest-friction option.

### Automation Integration Strategy

| Existing Script | Current Behavior | Required Change | Backward Compatible? |
|----------------|-----------------|-----------------|---------------------|
| [`Common-ScriptHelpers.psm1`](../../../process-framework/scripts/Common-ScriptHelpers.psm1) | Loads sub-modules, exports their functions | Load new `ExecutionVerification.psm1` sub-module; update fallback export list | **Yes** — purely additive |
| [`New-IntegrationNarrative.ps1`](../../../process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1) | Edits 3 files, returns warnings on partial failures | Wrap edits with `Assert-LineInFile`; register for soak | **Yes** — assertions surface bugs that were already broken; valid runs unaffected |
| [`New-Handbook.ps1`](../../../process-framework/scripts/file-creation/07-deployment/New-Handbook.ps1) | Multi-file pattern (auto-updates PD-documentation-map.md, etc.) | Same: wrap edits with `Assert-LineInFile`; register for soak | **Yes** — same logic |
| [`Update-ProcessImprovement.ps1`](../../../process-framework/scripts/update/Update-ProcessImprovement.ps1) | Updates IMP status | No change — but IMP-586 itself flips to Completed via this script | **Yes** — no change |

**New automation needed**:
- [`ExecutionVerification.psm1`](../../../process-framework/scripts/Common-ScriptHelpers/ExecutionVerification.psm1) (new sub-module — see above).
- No new `.ps1` invocation scripts. All soak helpers are PS module functions called from inside other scripts.

---

## 🔧 Implementation Roadmap

### Required Components Analysis

#### New Tasks Required

**None.** This extension does not introduce new tasks. It modifies one existing task ([PF-TSK-026](../../../process-framework/tasks/support/framework-extension-task.md)) and pilots adoption in two existing scripts.

#### Supporting Infrastructure Required
| Component Type | Name | Purpose | Priority |
|----------------|------|---------|----------|
| **Function** (in existing module) | `Assert-LineInFile` | Throws on missing pattern after a write | **HIGH** |
| **Function** (in existing module) | `Test-LineInFile` | Bool variant for conditional flows | **HIGH** |
| **Sub-module** | [`ExecutionVerification.psm1`](../../../process-framework/scripts/Common-ScriptHelpers/ExecutionVerification.psm1) | Soak counter management | **HIGH** |
| **Shareable state file** | [`script-soak-tracking.md`](../../../process-framework/state-tracking/permanent/script-soak-tracking.md) | Per-script soak state | **HIGH** |
| **Pilot adoption #1** | [`New-IntegrationNarrative.ps1`](../../../process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1) armored | Validate the helpers in the script with the original failure mode | **HIGH** |
| **Pilot adoption #2** | [`New-Handbook.ps1`](../../../process-framework/scripts/file-creation/07-deployment/New-Handbook.ps1) armored | Validate the helpers in a second script with similar pattern | **HIGH** |
| **Process integration #1** | [PF-TSK-026](../../../process-framework/tasks/support/framework-extension-task.md) finalization step | Register-on-creation hook for scripts created by framework extensions | **MEDIUM** |
| **Process integration #2** | [PF-TSK-001](../../../process-framework/tasks/support/new-task-creation-process.md) Session 2 finalization | Register-on-creation hook for scripts created by new tasks | **MEDIUM** |
| **Documentation entries** | [`PF-documentation-map.md`](../../../process-framework/PF-documentation-map.md) updates | Discoverability for future agents | **MEDIUM** |

#### Integration Points
| Integration Point | Current Framework Component | Integration Method |
|------------------|----------------------------|-------------------|
| Module loading | [`Common-ScriptHelpers.psm1`](../../../process-framework/scripts/Common-ScriptHelpers.psm1) facade | Append `"ExecutionVerification.psm1"` to `$SubModules` array |
| Function discovery | [`Common-ScriptHelpers/FileOperations.psm1`](../../../process-framework/scripts/Common-ScriptHelpers/FileOperations.psm1) | Add `Assert-LineInFile` / `Test-LineInFile` to module body and `Export-ModuleMember` |
| State persistence | `process-framework/state-tracking/permanent/` | New file `script-soak-tracking.md` follows existing tracking-file conventions (frontmatter + table + Update History) |
| Process hook (script created via framework extension) | [PF-TSK-026](../../../process-framework/tasks/support/framework-extension-task.md) finalization step | Add bullet: "For each new script, call `Register-SoakScript -ScriptId <relative-path>`" |
| Process hook (script created via new task creation) | [PF-TSK-001](../../../process-framework/tasks/support/new-task-creation-process.md) Session 2 finalization | Add bullet: "For each new document creation script, call `Register-SoakScript -ScriptId <relative-path>`" |
| Discoverability | [`PF-documentation-map.md`](../../../process-framework/PF-documentation-map.md) | Add entries under appropriate sections |
| Task registry separation of concern | [`process-framework-task-registry.md`](../../../process-framework/infrastructure/process-framework-task-registry.md) | Update PF-TSK-026 entry to list `script-soak-tracking.md` as an output |

### Multi-Session Implementation Plan

#### Session 1: Library Helpers (Assert-LineInFile / Test-LineInFile)
**Priority**: HIGH — these are the lowest-friction, highest-value piece. Can ship and start armoring scripts even before Sessions 2–4 land.
- [ ] Add `Assert-LineInFile` and `Test-LineInFile` to [`Common-ScriptHelpers/FileOperations.psm1`](../../../process-framework/scripts/Common-ScriptHelpers/FileOperations.psm1)
- [ ] Update fallback export list in [`Common-ScriptHelpers.psm1`](../../../process-framework/scripts/Common-ScriptHelpers.psm1) (the static list at lines 88–146)
- [ ] Manual smoke test: create a temp file, run helpers (positive and negative cases), confirm error messages are descriptive
- [ ] Verify import via `Import-Module Common-ScriptHelpers -Force` from a clean PowerShell session — confirm functions are available
- [ ] Update [`PF-documentation-map.md`](../../../process-framework/PF-documentation-map.md) with new function entries

#### Session 2: Soak Infrastructure (ExecutionVerification.psm1 + state file)
**Priority**: HIGH — the second helper. Can use Session 1's helpers internally for its own state file writes.
- [ ] Create [`ExecutionVerification.psm1`](../../../process-framework/scripts/Common-ScriptHelpers/ExecutionVerification.psm1) with `Register-SoakScript`, `Confirm-SoakInvocation`, `Test-ScriptInSoak`, `Get-SoakStatus`
- [ ] **Counter is hardcoded at 5** — no `-InitialCounter` parameter
- [ ] **WhatIf bypass**: `Test-ScriptInSoak` returns `$false` in WhatIf; `Confirm-SoakInvocation` is no-op in WhatIf
- [ ] Create the directory `process-framework/state-tracking/permanent/` if it doesn't yet exist (this is a new shareable location)
- [ ] Create empty [`process-framework/state-tracking/permanent/script-soak-tracking.md`](../../../process-framework/state-tracking/permanent/script-soak-tracking.md) with frontmatter, schema, and empty table
- [ ] Implement SHA256 hash-based auto-reset in `Test-ScriptInSoak`
- [ ] Update [`Common-ScriptHelpers.psm1`](../../../process-framework/scripts/Common-ScriptHelpers.psm1) facade to load the new sub-module
- [ ] Manual smoke test: register a dummy script, simulate invocations (success/failure/WhatIf), confirm state file updates correctly; modify dummy script, confirm hash-based reset triggers
- [ ] Update [`PF-documentation-map.md`](../../../process-framework/PF-documentation-map.md) with new sub-module entry and state file entry

#### Session 3: Pilot Adoption (Two scripts)
**Priority**: HIGH — proves the value with the script that triggered IMP-586 and a second script with the same pattern.
- [ ] Add `Assert-LineInFile` calls to [`New-IntegrationNarrative.ps1`](../../../process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1) after `Add-DocumentationMapEntry` and after the workflow-tracking row update
- [ ] Add `Test-ScriptInSoak` at script start; `Confirm-SoakInvocation` near the end
- [ ] Register [`New-IntegrationNarrative.ps1`](../../../process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1) for soak via `Register-SoakScript`
- [ ] Repeat for [`New-Handbook.ps1`](../../../process-framework/scripts/file-creation/07-deployment/New-Handbook.ps1) — identify edit sites with deterministic post-conditions; armor them; add soak hooks; register
- [ ] Manual integration test for each pilot: run in `-WhatIf` (verify bypass) and a real run (verify soak hooks fire and state file updates)

#### Session 4: Process Integration & Finalization
**Priority**: MEDIUM — closes the loop so future PF-TSK-026 sessions consistently register.
- [ ] Update [PF-TSK-026 task definition](../../../process-framework/tasks/support/framework-extension-task.md) finalization step with `Register-SoakScript` bullet
- [ ] Update [PF-TSK-001 task definition](../../../process-framework/tasks/support/new-task-creation-process.md) Session 2 finalization with `Register-SoakScript` bullet (and Full Mode Task Completion Checklist Session 2 verification block)
- [ ] Update [`process-framework-task-registry.md`](../../../process-framework/infrastructure/process-framework-task-registry.md) PF-TSK-026 and PF-TSK-001 entries to list `script-soak-tracking.md` as output
- [ ] Update [`PF-documentation-map.md`](../../../process-framework/PF-documentation-map.md) with all final entries
- [ ] Move concept doc to `process-framework-local/proposals/old/`
- [ ] Move temp state file to `process-framework-local/state-tracking/temporary/old/`
- [ ] Update PF-IMP-586 status to Completed via [`Update-ProcessImprovement.ps1`](../../../process-framework/scripts/update/Update-ProcessImprovement.ps1)
- [ ] Complete feedback form per session

### Out of Scope (Follow-Up IMPs)

After this extension proves itself via Session 3 pilot, broader rollout is intentionally deferred:

- **One master rollout IMP for broader adoption to existing scripts**: After Session 3 pilots prove the helpers, file a **single master rollout IMP** that armors all relevant existing scripts with `Assert-LineInFile` and (where applicable) registers them for soak. Triaged in one pass rather than per-script or per-category.
- **Python script support**: `feedback_db.py` and other Python tools are out of scope for this PS-only extension. A separate Python helper module could mirror the design.
- **`PF-SCR` ID prefix in [PF-id-registry.json](../../../process-framework/PF-id-registry.json)**: This concept uses relative-path-as-ID (Option α). Introducing proper `PF-SCR-NNN` IDs (with metadata in script `<#.NOTES#>` blocks) is filed as [PF-IMP-601](../../state-tracking/permanent/process-improvement-tracking.md) (LOW priority follow-up).

## 🎯 Success Criteria

### Functional Success Criteria
- [ ] **Assertion fails loudly**: a script that calls `Assert-LineInFile` with a non-matching pattern throws and exits non-zero. Tested with [`New-IntegrationNarrative.ps1`](../../../process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1) against a doc-map missing the expected section.
- [ ] **Assertion succeeds silently**: a successful match produces no extra output (script's existing success banner stands).
- [ ] **Soak counter decrements on success**: 5 successful `Confirm-SoakInvocation -Outcome success` calls flip status from Active Soak to Soak Complete.
- [ ] **Soak counter resets on failure**: a single `failure` outcome resets counter to 5.
- [ ] **WhatIf bypass works**: `-WhatIf` runs do NOT decrement, do NOT prompt, do NOT write to state file.
- [ ] **Hash auto-reset works**: editing a registered script's body, then invoking it, results in `Test-ScriptInSoak` detecting the hash change and resetting the counter to 5.
- [ ] **Pilot scripts run cleanly under the new infrastructure**: produces same outputs, surfaces the doc-map regex bug if reintroduced.

### Human Collaboration Requirements
- [ ] **Concept Approval**: Mandatory human review of this concept (revision 1.3 (concept-stage final, ready for Step 4 impact analysis)) before Phase 2 (state tracking & implementation roadmap).
- [ ] **Scope Validation**: Confirm PS-only scope, two hooks (PF-TSK-026 + PF-TSK-001 Session 2), two-pilot Session 3, Option α (relative-path-as-ID).
- [ ] **Integration Review**: Human review of the finalization sub-step text added to PF-TSK-026.
- [ ] **Final Validation**: Human confirms after Session 4 that PF-TSK-026 finalization reads clearly and `Get-SoakStatus` is discoverable.

### Technical & Integration Requirements
- [ ] **Multi-Session Design**: 4 sessions, each independently completable.
- [ ] **State Persistence**: [`script-soak-tracking.md`](../../../process-framework/state-tracking/permanent/script-soak-tracking.md) follows existing permanent state file conventions (frontmatter, table, Update History).
- [ ] **Component Interdependency**: Session 2 depends on Session 1; Session 3 depends on Sessions 1 & 2; Session 4 depends on all.
- [ ] **Framework Compatibility**: Helpers coexist with [`Validate-StateTracking.ps1`](../../../process-framework/scripts/validation/Validate-StateTracking.ps1) and Pester/pytest. No conflicts.
- [ ] **Documentation Consistency**: New artifacts registered in [`PF-documentation-map.md`](../../../process-framework/PF-documentation-map.md).
- [ ] **State Tracking Integrity**: [`script-soak-tracking.md`](../../../process-framework/state-tracking/permanent/script-soak-tracking.md) updated atomically per invocation.
- [ ] **Backward Compatibility**: All changes are additive. Existing scripts that don't adopt the helpers continue working unchanged.
- [ ] **Task Registry Separation of Concern**: [`process-framework-task-registry.md`](../../../process-framework/infrastructure/process-framework-task-registry.md) PF-TSK-026 entry updated to reflect new output (`script-soak-tracking.md`).

### Quality Success Criteria
- [ ] **Completeness**: All 4 helpers implemented and tested. Both pilot adopters armored.
- [ ] **Usability**: A script author needs ≤ 3 lines added to adopt `Assert-LineInFile` per edit site. Soak adoption is one-line at start, one-line at end.
- [ ] **Maintainability**: Helpers live in standard sub-module structure; no exotic dependencies (just `Get-FileHash` from PowerShell built-ins).
- [ ] **Documentation Quality**: Each helper has a `<#.SYNOPSIS / .DESCRIPTION / .EXAMPLE #>` comment-based help block.

## 📝 Next Steps

### Immediate Actions Required
1. **Human Review of this concept (revision 1.3 (concept-stage final, ready for Step 4 impact analysis))** — must happen before Phase 2.
2. **Confirm scope decisions** — PS-only? Two hooks (PF-TSK-026 + PF-TSK-001 Session 2)? Option α (relative-path-as-ID)?
3. **Authorize multi-session implementation** — proceed to Phase 2 (state tracking & roadmap).

### Implementation Preparation (after concept approval)
1. **Create temporary state file**: [`New-TempTaskState.ps1 -Variant FrameworkExtension -TaskName "Script Self-Verification"`](../../../process-framework/scripts/file-creation/support/New-TempTaskState.ps1).
2. **Verify PowerShell version compatibility**: SHA256 via `Get-FileHash` requires pwsh 5.1+ — already a project requirement.
3. **Confirm pilot scripts identified**: Pilot #1 = [`New-IntegrationNarrative.ps1`](../../../process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1); Pilot #2 = [`New-Handbook.ps1`](../../../process-framework/scripts/file-creation/07-deployment/New-Handbook.ps1).

---

## 📋 Human Review Checklist

**🚨 This concept (revision 1.3 (concept-stage final, ready for Step 4 impact analysis)) requires human review before implementation can begin.**

### Concept Validation
- [ ] **Extension Necessity**: Is the silent-success problem common enough to justify framework-level infrastructure? (Evidence: 4 duplicate TD filings + Theme 4 in [PF-REV-032](../../feedback/reviews/tools-review-20260422-111222.md).)
- [ ] **Scope Appropriateness**: Is "two helpers in shared infrastructure + one new state file + two task hooks + two-script pilot" the right scope?
- [ ] **Two-hook strategy**: Confirm both PF-TSK-026 (Framework Extension) and PF-TSK-001 (New Task Creation Process Session 2) get registration hooks since both can create new scripts.
- [ ] **Resource Requirements**: 4 sessions feasible? Any session that should be folded or split?

### Technical Review
- [ ] **Workflow Definition**: The 14-step Process Overview (Phases 1–4) is correct?
- [ ] **Hash-based auto-reset**: Confirm this is the intended interpretation of "as soon as there is code change it needs to be verified".
- [ ] **`Confirm-SoakInvocation` as function call (not Read-Host)**: Confirmed in Q&A.
- [ ] **Counter fixed at 5 (no parameter)**: Confirmed in Q&A.
- [ ] **WhatIf bypass**: Confirmed in Q&A. `Test-ScriptInSoak` returns `$false` in WhatIf; `Confirm-SoakInvocation` is no-op.
- [ ] **State file location** (`process-framework/state-tracking/permanent/script-soak-tracking.md`, shareable): Confirmed in Q&A.
- [ ] **Two-script pilot** (`New-IntegrationNarrative.ps1` + `New-Handbook.ps1`): Confirmed in Q&A.
- [ ] **State file schema** (Script ID, Hash, Counter, Status, Last Invocation, Last Outcome, Notes): Acceptable?
- [ ] **Implementation Roadmap**: Session order makes sense?

### Open Design Tensions (resolved during Q&A)

- [x] **Script ID column — Option α (relative-path-as-ID) vs Option β (new `PF-SCR` ID prefix)**: Sticking with Option α. Option β filed as [PF-IMP-601](../../state-tracking/permanent/process-improvement-tracking.md) (LOW priority follow-up).
- [x] **Stale soak handling**: No TTL/expiry. `Get-SoakStatus` exposes stale entries during periodic human review (e.g., Tools Review sessions). Acceptable per directive.

### Approval Decision
- [ ] **APPROVED**: Concept is approved for implementation
- [ ] **NEEDS REVISION**: Concept needs changes before approval
- [ ] **REJECTED**: Concept is not suitable for framework extension

**Human Reviewer**: Ronny Wette
**Review Date**: 2026-04-27
**Decision**: [APPROVED / NEEDS REVISION / REJECTED]
**Comments**: [Review comments and feedback]

---

*This concept document was created using the Framework Extension Concept Template (PF-TEM-032) as part of the Framework Extension Task ([PF-TSK-026](../../../process-framework/tasks/support/framework-extension-task.md)). Originating IMP: [PF-IMP-586](../../state-tracking/permanent/process-improvement-tracking.md).*
