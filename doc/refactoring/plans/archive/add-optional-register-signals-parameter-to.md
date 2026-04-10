---
id: PD-REF-183
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-09
updated: 2026-04-09
refactoring_scope: Add optional register_signals parameter to LinkWatcherService constructor
mode: lightweight
priority: Medium
target_area: LinkWatcherService
---

# Lightweight Refactoring Plan: Add optional register_signals parameter to LinkWatcherService constructor

- **Target Area**: LinkWatcherService
- **Priority**: Medium
- **Created**: 2026-04-09
- **Author**: AI Agent & Human Partner
- **Status**: Planning
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD197 — Add optional register_signals parameter to LinkWatcherService

**Scope**: Add `register_signals: bool = True` parameter to `LinkWatcherService.__init__()`. When `False`, skip `signal.signal()` calls on lines 92-93 of service.py. This allows embedding the service in test harnesses or larger applications that manage their own signal handlers. Default `True` preserves existing behavior. Dimension: EM (Extensibility/Maintainability).

**Changes Made**:
- [x] Add `register_signals=True` parameter to `__init__()` signature (service.py:54)
- [x] Wrap signal.signal() calls in `if register_signals:` guard (service.py:92-94)
- [x] Update `test_signal_handler_setup` to use `signal.getsignal()` assertion (test_service.py:227)
- [x] Add `test_signal_handler_skipped_when_disabled` test (test_service.py:235-244)

**Test Baseline**: 758 passed, 5 skipped, 4 deselected, 4 xfailed (0 failures)
**Test Result**: 759 passed, 5 skipped, 4 deselected, 4 xfailed (0 failures) — +1 new test, 0 regressions

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.1) updated — signal handler decision note updated with `register_signals=False` opt-out
- [x] TDD (0.1.1) updated — `__init__` signature, code snippet, and diagram updated with `register_signals` parameter
- [ ] Test spec (0.1.1) — N/A: _Grepped test-spec-0-1-1 — references signal handling gap (line 276) which is now partially addressed by new test, but spec describes coverage gaps not behavioral contracts; no update needed_
- [ ] FDD (0.1.1) — N/A: _Grepped fdd-0-1-1 — signal references are functional requirements (FR-5) about graceful shutdown behavior, which is unchanged_
- [x] ADR (orchestrator-facade-pattern) updated — consequence note updated to reflect opt-out via `register_signals=False`
- [ ] Validation tracking — N/A: _Feature 0.1.1 validation rounds are archived (tracking-1 through tracking-3); current tracking-4 does not include 0.1.1_
- [ ] Technical Debt Tracking: TD item to be marked resolved in L10

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD197 | Complete | None | TDD, ADR, feature state file |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
