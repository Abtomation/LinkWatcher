---
id: PF-SST-001
type: Process Framework
category: Shareable State Tracking
version: 1.0
created: 2026-04-27
updated: 2026-04-27
---

# Script Soak Tracking

This file tracks the soak-verification state of PowerShell scripts registered via `Register-SoakScript`. While in soak, every successful invocation of the script must be explicitly confirmed by the agent (via `Confirm-SoakInvocation -Outcome success`); five consecutive successes flip the status to `Soak Complete`. A failure or a script-body change resets the counter back to 5 so the script is re-verified.

> **ID prefix**: `PF-SST` (Shareable State Tracking) — registered in [`process-framework/PF-id-registry.json`](../../PF-id-registry.json), the shareable framework registry that travels with the framework across projects. Distinct from `PF-STA` (project-local state tracking under `process-framework-local/`).

## Status Legend

| Status | Description | Behavior |
|--------|-------------|----------|
| Active Soak | Counter > 0; awaiting more confirmed-success invocations | `Test-ScriptInSoak` returns `$true`; agent must call `Confirm-SoakInvocation` after each run |
| Soak Complete | Counter == 0; script has demonstrated 5 consecutive successful invocations with no failures since registration or last hash change | `Test-ScriptInSoak` returns `$false`; agent skips the confirmation step (only `Assert-LineInFile` calls keep guarding) |

## Counter Semantics

- **Initial value**: 5 (set by `Register-SoakScript`).
- **Decrement**: each `Confirm-SoakInvocation -Outcome success` decrements by 1.
- **Reset to 5**: triggered by (a) `Confirm-SoakInvocation -Outcome failure`, or (b) `Test-ScriptInSoak` detecting that the script's content hash differs from the registered hash (auto-reset on script-body change — no manual call needed).
- **Bypass**: when `$WhatIfPreference` is true, `Test-ScriptInSoak` returns `$false` immediately and `Confirm-SoakInvocation` is a no-op. WhatIf runs do not produce real edits, so they must not count toward soak progress.

## Registered Scripts

| Script ID | Content Hash | Current Counter | Status | Last Invocation | Last Outcome | Notes |
|-----------|--------------|-----------------|--------|-----------------|--------------|-------|
| process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1 | 6876B1859D64861C7887F8E6A77C645744FDC0E940A08C4AD14280636F804AD9 | 4 | Active Soak | 2026-04-27 | success | PF-TSK-026 Phase 4 pilot adopter (IMP-586 trigger) |
| process-framework/scripts/file-creation/07-deployment/New-Handbook.ps1 | C34F153005462FEE34163A9B624B69A9B3BBD19EAB5DAE27F6A803A23BDAC407 | 5 | Active Soak | — | — | PF-TSK-026 Phase 4 second pilot |
<!-- New rows are appended above this comment by Register-SoakScript. -->

## Update History

| Date | Action | Actor |
|------|--------|-------|
| 2026-04-27 | File created (Phase 3 of PF-TSK-026 Script Self-Verification) | AI Agent (PF-TSK-026) |
| 2026-04-27 | Registered process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1 (counter=5) | Register-SoakScript |
| 2026-04-27 | Registered process-framework/scripts/file-creation/07-deployment/New-Handbook.ps1 (counter=5) | Register-SoakScript |
| 2026-04-27 | Counters reset 4 -> 5 for both pilots after Phase 4 -WhatIf bypass bug discovery; spurious "Confirmed success" rows from -WhatIf invocations removed (module-isolation defect in WhatIf detection — fixed in ExecutionVerification.psm1 _Test-CallerWhatIf) | AI Agent (PF-TSK-026 Phase 4) |
| 2026-04-27 | Confirmed success for process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1; counter 5 -> 4 | Confirm-SoakInvocation |
<!-- New rows are appended above this comment by Register-SoakScript / Confirm-SoakInvocation. -->
