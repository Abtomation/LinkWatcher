---
id: PD-REF-115
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-27
updated: 2026-03-27
mode: lightweight
refactoring_scope: Add target-existence cache to check_links to deduplicate os.path.exists syscalls
priority: Medium
target_area: Core Architecture
---

# Lightweight Refactoring Plan: Add target-existence cache to check_links to deduplicate os.path.exists syscalls

- **Target Area**: Core Architecture
- **Priority**: Medium
- **Created**: 2026-03-27
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD109 — Deduplicate os.path.exists() calls in check_links()

**Scope**: `check_links()` in service.py iterates `get_all_targets_with_references()` which groups references by target_path. The inner loop calls `os.path.exists()` once per reference, but all references under the same target share the same path. Move the exists check outside the inner loop so it runs once per target, avoiding N-1 redundant syscalls per target.

**Changes Made**:
- [x] Move `os.path.exists()` call outside inner `for ref in references` loop in `check_links()` (service.py:257-263)
- [x] Replace per-ref `total_checked += 1` with per-target `total_checked += len(references)`

**Test Baseline**: test_service.py — 24 passed; full suite — 597 passed, 5 skipped, 7 xfailed
**Test Result**: test_service.py — 24 passed; full suite — 597 passed, 5 skipped, 7 xfailed. No new failures.

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.1) updated, or N/A — _Grepped state file for `check_links` — no matches. No update needed._
- [x] TDD (0.1.1) updated, or N/A — _Grepped TDD for `check_links` — no matches. No update needed._
- [x] Test spec (0.1.1) updated, or N/A — _Grepped test-spec-0-1-1: mentions `check_links` test cases. No behavior change — internal optimization only, same return values. No update needed._
- [x] FDD (0.1.1) updated, or N/A — _Grepped FDDs for `check_links` — no matches. No update needed._
- [x] ADR updated, or N/A — _Grepped ADR directory for `check_links` — no matches. No update needed._
- [x] Validation tracking updated, or N/A — _R2-L-008 in validation-tracking-2.md line 234 references this issue. Will be updated when TD109 is marked resolved via Update-TechDebt.ps1._
- [x] Technical Debt Tracking: TD109 marked resolved via Update-TechDebt.ps1 + manual validation-tracking-2.md update

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD109 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
