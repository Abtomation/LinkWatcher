---
id: PD-REF-205
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-29
updated: 2026-04-29
refactoring_scope: TD224 - Harden New-IntegrationNarrative.ps1 workflow-tracking write
debt_item: TD224
target_area: process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1
mode: lightweight
priority: Medium
---

# Lightweight Refactoring Plan: TD224 - Harden New-IntegrationNarrative.ps1 workflow-tracking write

- **Target Area**: process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1
- **Priority**: Medium
- **Created**: 2026-04-29
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Debt Item**: TD224
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD224 — Harden New-IntegrationNarrative.ps1 workflow-tracking write

**Scope**: TD224 reported a one-shot occurrence (2026-04-22, WF-004) where the script printed success but the workflow-tracking edit did not persist. A subsequent commit (`130b3ea`) already added `Assert-LineInFile` after the workflow-tracking write, which converts any future silent failure into a hard throw — addressing the "silent success is worse than visible failure" concern in TD224. The underlying root cause could not be reproduced in isolation; the algorithm works correctly when tested against a temp copy. This refactoring adds defense-in-depth to eliminate the most plausible residual cause: implicit encoding behavior in `Get-Content`/`Set-Content` could mangle non-ASCII characters (`→`, `✅`) if the script were ever invoked from Windows PowerShell 5.1 instead of pwsh.exe. Also removes a small piece of dead code on the same lines.

**Dim** (from technical-debt-tracking.md): CQ (Code Quality).

**Changes Made**:
- [x] Removed dead `$trackingContent = Get-Content $workflowTrackingPath -Raw` (was line 162; assigned but never read)
- [x] Added `-Encoding UTF8` to the active `Get-Content` of `user-workflow-tracking.md` (now line 162)
- [x] Added `-Encoding UTF8` to the `Set-Content` write of `user-workflow-tracking.md` (now line 208)

**Test Baseline**: 815 passed, 5 skipped, 4 deselected, 5 xfailed in 41.40s — clean (0 failures).
**Test Result**: 815 passed, 5 skipped, 4 deselected, 5 xfailed in 42.77s — **identical to baseline, 0 new failures**.

**Verification beyond regression**:
- PowerShell static parse: OK
- Isolated end-to-end test of changed code path (blanked WF-005 cell, ran the modified algorithm against a temp copy):
  - docLink persists in the file (Assert-LineInFile equivalent passes)
  - Multi-byte UTF-8 characters (`→`, `✅`) preserved verbatim
  - File still has no BOM under pwsh 7+ (`-Encoding UTF8` is a no-op for the default shell, as expected)

**Documentation & State Updates**:
<!-- Test-only / process-framework-tooling shortcut: this script is process-framework tooling, not product code -->
- [x] N/A (items 1–7) — Process-framework script change with no product code impact. The script writes to `user-workflow-tracking.md`; no FDD/TDD/ADR/test spec/validation-tracking entries describe the script's encoding behavior or the workflow-tracking row write. Verified by grepping the doc tree (`grep -r "New-IntegrationNarrative"`) — references are limited to PF-documentation-map.md and the script's own customization guide, neither of which describes the encoding contract being changed.
- [x] Technical Debt Tracking: TD224 marked Resolved via `Update-TechDebt.ps1`

**Bugs Discovered**: None expected — change is defensive only.

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD224 | Complete | None | None (process-framework tooling change; no product docs reference the encoding contract) |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
