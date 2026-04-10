---
id: PD-REF-161
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-08
updated: 2026-04-08
priority: Medium
target_area: E2E Acceptance Testing
mode: lightweight
refactoring_scope: Add run.ps1 automation scripts to E2E test cases TE-E2E-001, 002, 003
debt_item: TD173
---

# Lightweight Refactoring Plan: Add run.ps1 automation scripts to E2E test cases TE-E2E-001, 002, 003

- **Target Area**: E2E Acceptance Testing
- **Priority**: Medium
- **Created**: 2026-04-08
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Debt Item**: TD173
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD173 — Add run.ps1 scripts to TE-E2E-001, 002, 003

**Scope**: E2E test cases TE-E2E-001 (regex preserved on file move), TE-E2E-002 (PowerShell markdown file move), and TE-E2E-003 (PowerShell script file move) lack `run.ps1` automation scripts. All newer test cases (004+) have them. Creating 3 `run.ps1` files following the established pattern so these test cases can be executed by `Run-E2EAcceptanceTest.ps1`. Note: TD173 description says 001-004 but 004 already has a run.ps1 — actual gap is 001-003 only.

**Changes Made**:
- [x] Create `test/e2e-acceptance-testing/templates/powershell-regex-preservation/TE-E2E-001-regex-preserved-on-file-move/run.ps1`
- [x] Create `test/e2e-acceptance-testing/templates/powershell-parser-patterns/TE-E2E-002-powershell-md-file-move/run.ps1`
- [x] Create `test/e2e-acceptance-testing/templates/powershell-parser-patterns/TE-E2E-003-powershell-script-file-move/run.ps1`

**Test Baseline**: Test-only change (new test automation scripts, no production code) — test baseline skipped.
**Test Result**: Test-only change — regression testing skipped. All 3 scripts parse without syntax errors.

**Documentation & State Updates**:
Test-only refactoring — no production code changes; design and state documents do not reference test internals. Items 1–6 N/A.
- [N/A] Feature implementation state file — Test-only refactoring — no production code changes
- [N/A] TDD — Test-only refactoring — no production code changes
- [N/A] Test spec — Test-only refactoring — no production code changes
- [N/A] FDD — Test-only refactoring — no production code changes
- [N/A] ADR — Test-only refactoring — no production code changes
- [N/A] Validation tracking — Test-only refactoring — no production code changes
- [ ] Technical Debt Tracking: TD173 marked resolved

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD173 | Complete | None | None (test-only) |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
