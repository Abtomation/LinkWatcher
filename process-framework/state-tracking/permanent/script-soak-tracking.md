---
id: PF-SST-001
type: Process Framework
category: Shareable State Tracking
version: 2.0
created: 2026-04-27
updated: 2026-05-05
---

# Script Soak Tracking

This file tracks the soak-verification state of PowerShell scripts registered via `Register-SoakScript`. While in soak, every successful invocation of the script must be explicitly confirmed by the agent (via `Confirm-SoakInvocation -Outcome success`); `$DefaultSoakCounter` consecutive successes (default 3 in v2.0; was 5 in v1.x) flip the status to `Soak Complete`. A failure or a script-body change resets the counter back to `$DefaultSoakCounter` so the script is re-verified.

> **ID prefix**: `PF-SST` (Shareable State Tracking) — registered in [`process-framework/PF-id-registry.json`](../../PF-id-registry.json), the shareable framework registry that travels with the framework across projects. Distinct from `PF-STA` (project-local state tracking under `process-framework-local/`).

> **v2.0 (PF-IMP-728)**: default counter lowered from 5 to 3; caller-aware mode added — `Register-SoakScript` / `Test-ScriptInSoak` / `Confirm-SoakInvocation` accept zero positional args and resolve the calling `.ps1` from `Get-PSCallStack` (skipping `.psm1` frames). Existing callers passing `-ScriptId`/`-ScriptPath` are unchanged. See [PF-PRO-028](../../../process-framework-local/proposals/old/script-self-verification.md) v2.0 Lessons Learned for rationale.

## Status Legend

| Status | Description | Behavior |
|--------|-------------|----------|
| Active Soak | Counter > 0; awaiting more confirmed-success invocations | `Test-ScriptInSoak` returns `$true`; agent must call `Confirm-SoakInvocation` after each run |
| Soak Complete | Counter == 0; script has demonstrated `$DefaultSoakCounter` (default 3) consecutive successful invocations with no failures since registration or last hash change | `Test-ScriptInSoak` returns `$false`; agent skips the confirmation step (only `Assert-LineInFile` calls keep guarding) |

## Counter Semantics

- **Initial value**: `$DefaultSoakCounter` (default 3 in v2.0; configurable at module top in [`ExecutionVerification.psm1`](../../scripts/Common-ScriptHelpers/ExecutionVerification.psm1)).
- **Decrement**: each `Confirm-SoakInvocation -Outcome success` decrements by 1.
- **Reset to `$DefaultSoakCounter`**: triggered by (a) `Confirm-SoakInvocation -Outcome failure`, or (b) `Test-ScriptInSoak` detecting that the script's content hash differs from the registered hash (auto-reset on script-body change — no manual call needed).
- **Bypass**: when `$WhatIfPreference` is true, `Test-ScriptInSoak` returns `$false` immediately and `Confirm-SoakInvocation` is a no-op. WhatIf runs do not produce real edits, so they must not count toward soak progress. Module helpers read the caller's preference explicitly via `_Test-CallerWhatIf` (see PF-PRO-028 v2.0 Lessons Learned for the 2026-04-27 module-isolation incident this pattern guards against).

## Registered Scripts

| Script ID | Content Hash | Current Counter | Status | Last Invocation | Last Outcome | Notes |
|-----------|--------------|-----------------|--------|-----------------|--------------|-------|
| process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1 | 6876B1859D64861C7887F8E6A77C645744FDC0E940A08C4AD14280636F804AD9 | 3 | Active Soak | 2026-04-27 | success | PF-TSK-026 Phase 4 pilot adopter (IMP-586 trigger); counter clamped 4→3 on 2026-05-05 (PF-IMP-728 v2.0 default change); Pattern A code removed on 2026-05-05 (PF-IMP-733), now relies on Pattern B helper-routed armoring (DocumentManagement.psm1) only — counter will auto-reset on next invocation (hash change) |
| process-framework/scripts/file-creation/07-deployment/New-Handbook.ps1 | C34F153005462FEE34163A9B624B69A9B3BBD19EAB5DAE27F6A803A23BDAC407 | 3 | Active Soak | — | — | PF-TSK-026 Phase 4 second pilot; counter clamped 5→3 on 2026-05-05 (PF-IMP-728 v2.0 default change); Pattern A code removed on 2026-05-05 (PF-IMP-733), now relies on Pattern B helper-routed armoring (DocumentManagement.psm1) only — counter will auto-reset on next invocation (hash change) |
| process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1 | 1276C45E4FFB10AE94CA63E50740C88889EC710C0A470E336BB4ADAB36A06F85 | 2 | Active Soak | 2026-05-05 | success | Adopted opportunistically post-pilot during PF-IMP-685 review (PF-TSK-009 session 2026-04-29) |
| process-framework/scripts/update/Update-TechDebt.ps1 | 0FE16D3458A4386CDB80B3D4CA064A75395A4F18EBFC95C12CE437017A715C54 | 3 | Active Soak | — | — | Phase 4 pilot rollout adopter (PF-IMP-685 decision: extend assert+soak pattern to high-frequency update scripts); counter clamped 5→3 on 2026-05-05 (PF-IMP-728 v2.0 default change) |
| process-framework/scripts/update/Update-BugStatus.ps1 | 95CCC922FC451F7BCF440576A3AA77E618000F3B5525CD671B913F9215DD6D08 | 3 | Active Soak | — | — | Phase 4 pilot rollout adopter (PF-IMP-685 decision: extend assert+soak pattern to high-frequency update scripts); counter clamped 5→3 on 2026-05-05 (PF-IMP-728 v2.0 default change) |
| process-framework/scripts/update/Update-ProcessImprovement.ps1 | 19AFD89EEBA10F58F9D01BFF281330FF48B32105282D38C2F1001425A01C5A2C | 0 | Soak Complete | 2026-05-05 | success | Phase 4 pilot rollout adopter (PF-IMP-685 / IMP-696: 3rd backfill candidate, completing Option B rollout) |
| process-framework/scripts/file-creation/support/New-FeedbackForm.ps1 | 6C852E9759822EF160D4F2BFEB3C184D31D6E438C42A6F86B393E6DCD9F10B12 | 0 | Soak Complete | 2026-05-05 | success |  |
<!-- New rows are appended above this comment by Register-SoakScript. -->

## Update History

| Date | Action | Actor |
|------|--------|-------|
| 2026-04-27 | File created (Phase 3 of PF-TSK-026 Script Self-Verification) | AI Agent (PF-TSK-026) |
| 2026-04-27 | Registered process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1 (counter=5) | Register-SoakScript |
| 2026-04-27 | Registered process-framework/scripts/file-creation/07-deployment/New-Handbook.ps1 (counter=5) | Register-SoakScript |
| 2026-04-27 | Counters reset 4 -> 5 for both pilots after Phase 4 -WhatIf bypass bug discovery; spurious "Confirmed success" rows from -WhatIf invocations removed (module-isolation defect in WhatIf detection — fixed in ExecutionVerification.psm1 _Test-CallerWhatIf) | AI Agent (PF-TSK-026 Phase 4) |
| 2026-04-27 | Confirmed success for process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1; counter 5 -> 4 | Confirm-SoakInvocation |
| 2026-04-29 | Registered process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1 (counter=5) | Register-SoakScript |
| 2026-04-29 | Confirmed success for process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1; counter 5 -> 4 | Confirm-SoakInvocation |
| 2026-04-30 | Hash mismatch for process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1; auto-reset counter to 5 | Test-ScriptInSoak (auto) |
| 2026-04-30 | Confirmed success for process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1; counter 5 -> 4 | Confirm-SoakInvocation |
| 2026-04-30 | Confirmed success for process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1; counter 4 -> 3 | Confirm-SoakInvocation |
| 2026-04-30 | Confirmed success for process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1; counter 3 -> 2 | Confirm-SoakInvocation |
| 2026-05-01 | Confirmed success for process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1; counter 2 -> 1 | Confirm-SoakInvocation |
| 2026-05-01 | Confirmed success for process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1; counter 1 -> 0 | Confirm-SoakInvocation |
| 2026-05-04 | Registered process-framework/scripts/update/Update-TechDebt.ps1 (counter=5) | Register-SoakScript |
| 2026-05-04 | Registered process-framework/scripts/update/Update-BugStatus.ps1 (counter=5) | Register-SoakScript |
| 2026-05-04 | Hash mismatch for process-framework/scripts/update/Update-TechDebt.ps1; auto-reset counter to 5 | Test-ScriptInSoak (auto) |
| 2026-05-04 | Registered process-framework/scripts/update/Update-ProcessImprovement.ps1 (counter=5) | Register-SoakScript |
| 2026-05-04 | Confirmed success for process-framework/scripts/update/Update-ProcessImprovement.ps1; counter 5 -> 4 | Confirm-SoakInvocation |
| 2026-05-04 | Confirmed success for process-framework/scripts/update/Update-ProcessImprovement.ps1; counter 4 -> 3 | Confirm-SoakInvocation |
| 2026-05-04 | Confirmed success for process-framework/scripts/update/Update-ProcessImprovement.ps1; counter 3 -> 2 | Confirm-SoakInvocation |
| 2026-05-04 | Confirmed success for process-framework/scripts/update/Update-ProcessImprovement.ps1; counter 2 -> 1 | Confirm-SoakInvocation |
| 2026-05-04 | Hash mismatch for process-framework/scripts/update/Update-ProcessImprovement.ps1; auto-reset counter to 5 | Test-ScriptInSoak (auto) |
| 2026-05-04 | Confirmed success for process-framework/scripts/update/Update-ProcessImprovement.ps1; counter 5 -> 4 | Confirm-SoakInvocation |
| 2026-05-04 | Confirmed success for process-framework/scripts/update/Update-ProcessImprovement.ps1; counter 4 -> 3 | Confirm-SoakInvocation |
| 2026-05-04 | Confirmed success for process-framework/scripts/update/Update-ProcessImprovement.ps1; counter 3 -> 2 | Confirm-SoakInvocation |
| 2026-05-04 | Confirmed success for process-framework/scripts/update/Update-ProcessImprovement.ps1; counter 2 -> 1 | Confirm-SoakInvocation |
| 2026-05-04 | Confirmed success for process-framework/scripts/update/Update-ProcessImprovement.ps1; counter 1 -> 0 | Confirm-SoakInvocation |
| 2026-05-04 | Hash mismatch for process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1; auto-reset counter to 5 | Test-ScriptInSoak (auto) |
| 2026-05-04 | Confirmed success for process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1; counter 5 -> 4 | Confirm-SoakInvocation |
| 2026-05-04 | Confirmed success for process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1; counter 4 -> 3 | Confirm-SoakInvocation |
| 2026-05-04 | Confirmed success for process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1; counter 3 -> 2 | Confirm-SoakInvocation |
| 2026-05-05 | Confirmed success for process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1; counter 2 -> 1 | Confirm-SoakInvocation |
| 2026-05-05 | Hash mismatch for process-framework/scripts/update/Update-ProcessImprovement.ps1; auto-reset counter to 5 | Test-ScriptInSoak (auto) |
| 2026-05-05 | Confirmed success for process-framework/scripts/update/Update-ProcessImprovement.ps1; counter 5 -> 4 | Confirm-SoakInvocation |
| 2026-05-05 | Confirmed success for process-framework/scripts/update/Update-ProcessImprovement.ps1; counter 4 -> 3 | Confirm-SoakInvocation |
| 2026-05-05 | Confirmed success for process-framework/scripts/update/Update-ProcessImprovement.ps1; counter 3 -> 2 | Confirm-SoakInvocation |
| 2026-05-05 | Hash mismatch for process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1; auto-reset counter to 5 | Test-ScriptInSoak (auto) |
| 2026-05-05 | Confirmed success for process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1; counter 5 -> 4 | Confirm-SoakInvocation |
| 2026-05-05 | Confirmed success for process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1; counter 4 -> 3 | Confirm-SoakInvocation |
| 2026-05-05 | Confirmed success for process-framework/scripts/update/Update-ProcessImprovement.ps1; counter 2 -> 1 | Confirm-SoakInvocation |
| 2026-05-05 | Confirmed success for process-framework/scripts/update/Update-ProcessImprovement.ps1; counter 1 -> 0 | Confirm-SoakInvocation |
| 2026-05-05 | Registered process-framework-local/scratch/soak-smoke-A.ps1 (counter=3) | Register-SoakScript (PF-IMP-728 mid-session smoke gate) |
| 2026-05-05 | Registered process-framework-local/scratch/soak-smoke-B.ps1 (counter=3) | Register-SoakScript (PF-IMP-728 mid-session smoke gate) |
| 2026-05-05 | Confirmed success for process-framework-local/scratch/soak-smoke-A.ps1; counter 3 -> 2 | Confirm-SoakInvocation (PF-IMP-728 mid-session smoke gate) |
| 2026-05-05 | Hash mismatch for process-framework-local/scratch/soak-smoke-A.ps1; auto-reset counter to 3 | Test-ScriptInSoak (auto) (PF-IMP-728 mid-session smoke gate) |
| 2026-05-05 | PF-IMP-728 mid-session smoke gate PASSED (5 tests: register / test-in-soak / per-script granularity / -WhatIf bypass / hash-reset). Removed smoke-A and smoke-B Registered Scripts rows after verification. | AI Agent (PF-TSK-026) |
| 2026-05-05 | PF-IMP-728 v2.0: $DefaultSoakCounter default lowered 5 → 3 in ExecutionVerification.psm1; clamped 4 in-flight counters: New-IntegrationNarrative.ps1 4→3, New-Handbook.ps1 5→3, Update-TechDebt.ps1 5→3, Update-BugStatus.ps1 5→3. Counter values preserved for entries already at ≤3 (New-ProcessImprovement.ps1 unchanged at 3) or already Soak Complete (Update-ProcessImprovement.ps1 unchanged at 0). | AI Agent (PF-TSK-026) |
| 2026-05-05 | Hash mismatch for process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1; auto-reset counter to 3 | Test-ScriptInSoak (auto) |
| 2026-05-05 | Confirmed success for process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1; counter 3 -> 2 | Confirm-SoakInvocation |
| 2026-05-05 | Registered process-framework-local/scratch/soak-helper-smoke-A.ps1 (counter=3) | Register-SoakScript (PF-IMP-728 Session 2 helper smoke gate) |
| 2026-05-05 | Confirmed success for process-framework-local/scratch/soak-helper-smoke-A.ps1; counter 3 -> 2 | Confirm-SoakInvocation (PF-IMP-728 Session 2 helper smoke gate; Pattern B caller-aware mode verified) |
| 2026-05-05 | Hash mismatch for process-framework-local/scratch/soak-helper-smoke-A.ps1; auto-reset counter to 3 | Test-ScriptInSoak (auto) (PF-IMP-728 Session 2 helper smoke gate; Pattern B hash auto-reset verified) |
| 2026-05-05 | Confirmed success for process-framework-local/scratch/soak-helper-smoke-A.ps1; counter 3 -> 2 | Confirm-SoakInvocation (PF-IMP-728 Session 2 helper smoke gate) |
| 2026-05-05 | PF-IMP-728 Session 2 HELPER smoke gate PASSED (4 tests via Pattern B helper-routed armoring of DocumentManagement.psm1 New-ProjectDocumentWithMetadata: caller-aware decrement / hash auto-reset / -WhatIf bypass for catch-path Confirm / per-script granularity preserved). The 2026-04-27 module-isolation -WhatIf bypass bug does NOT regress in Pattern B. Removed soak-helper-smoke-A Registered Scripts row after verification. | AI Agent (PF-TSK-026 Session 2) |
| 2026-05-05 | Confirmed success for process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1; counter 2 -> 1 | Confirm-SoakInvocation |
| 2026-05-05 | Confirmed success for process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1; counter 1 -> 0 | Confirm-SoakInvocation |
| 2026-05-05 | Registered process-framework/scripts/file-creation/support/New-FeedbackForm.ps1 (counter=3) | Register-SoakScript |
| 2026-05-05 | Confirmed success for process-framework/scripts/file-creation/support/New-FeedbackForm.ps1; counter 3 -> 2 | Confirm-SoakInvocation |
| 2026-05-05 | Hash mismatch for process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1; auto-reset counter to 3 | Test-ScriptInSoak (auto) |
| 2026-05-05 | Confirmed success for process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1; counter 3 -> 2 | Confirm-SoakInvocation |
| 2026-05-05 | Confirmed success for process-framework/scripts/file-creation/support/New-FeedbackForm.ps1; counter 2 -> 1 | Confirm-SoakInvocation |
| 2026-05-05 | Registered process-framework-local/scratch/soak-whatif-smoke.ps1 (counter=3) | Register-SoakScript (PF-IMP-728 Session 2 WhatIf short-circuit fix verification) |
| 2026-05-05 | Confirmed success for process-framework-local/scratch/soak-whatif-smoke.ps1; counter 3 -> 2 | Confirm-SoakInvocation (PF-IMP-728 Session 2 WhatIf short-circuit normal-path verification — counter drains correctly) |
| 2026-05-05 | PF-IMP-728 Session 2 WhatIf short-circuit fix verified (2 tests via synthetic caller invoking New-ProjectDocumentWithMetadata): under -WhatIf the helper returns $true with no Set-Content / no Assert / no Confirm (counter unchanged at 3); normal invocation drains counter (3->2 with success outcome). DocumentManagement.psm1 helpers now restore pre-armoring -WhatIf behavior (silent success preview) instead of loud Assert failure. Add-DocumentationMapEntry already handled by existing ShouldProcess check at line 942 (no fix needed there). Removed soak-whatif-smoke Registered Scripts row after verification. | AI Agent (PF-TSK-026 Session 2) |
| 2026-05-05 | Hash mismatch for process-framework/scripts/update/Update-ProcessImprovement.ps1; auto-reset counter to 3 | Test-ScriptInSoak (auto) |
| 2026-05-05 | Confirmed success for process-framework/scripts/update/Update-ProcessImprovement.ps1; counter 3 -> 2 | Confirm-SoakInvocation |
| 2026-05-05 | Hash mismatch for process-framework/scripts/update/Update-ProcessImprovement.ps1; auto-reset counter to 3 | Test-ScriptInSoak (auto) |
| 2026-05-05 | Confirmed success for process-framework/scripts/update/Update-ProcessImprovement.ps1; counter 3 -> 2 | Confirm-SoakInvocation |
| 2026-05-05 | Confirmed success for process-framework/scripts/update/Update-ProcessImprovement.ps1; counter 2 -> 1 | Confirm-SoakInvocation |
| 2026-05-05 | Confirmed success for process-framework/scripts/update/Update-ProcessImprovement.ps1; counter 1 -> 0 | Confirm-SoakInvocation |
| 2026-05-05 | Confirmed success for process-framework/scripts/file-creation/support/New-FeedbackForm.ps1; counter 1 -> 0 | Confirm-SoakInvocation |
| 2026-05-05 | PF-IMP-733: Removed redundant explicit Pattern A code (Test-ScriptInSoak / Confirm-SoakInvocation calls) from New-IntegrationNarrative.ps1 and New-Handbook.ps1; both now use single-line Register-SoakScript opt-in (Pattern B, helper-routed via DocumentManagement.psm1). Eliminates ~3x counter drain per invocation. Hash change will trigger auto-reset to 3 on next invocation per PF-PRO-028 v2.0. | AI Agent (PF-TSK-009) |
| 2026-05-05 | Confirmed success for process-framework/scripts/file-creation/support/New-FeedbackForm.ps1; counter 0 -> 0 | Confirm-SoakInvocation |
<!-- New rows are appended above this comment by Register-SoakScript / Confirm-SoakInvocation. -->
