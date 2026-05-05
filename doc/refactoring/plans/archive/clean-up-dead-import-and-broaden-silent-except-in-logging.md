---
id: PD-REF-211
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-29
updated: 2026-04-29
target_area: tools/logging_dashboard.py
mode: lightweight
refactoring_scope: Clean up dead import and broaden silent except in logging dashboard
priority: Medium
---

# Lightweight Refactoring Plan: Clean up dead import and broaden silent except in logging dashboard

- **Target Area**: tools/logging_dashboard.py
- **Priority**: Medium
- **Created**: 2026-04-29
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: No TD ID — Clean up dead import and silent blanket except in logging dashboard

**Scope**: Three small code-quality fixes to `tools/logging_dashboard.py` (a documented user-facing diagnostic TUI):
1. Remove unused `from linkwatcher.logging_config import get_config_manager` (line 30) — the imported name is never referenced.
2. Remove the `sys.path.insert(0, str(Path(__file__).parent.parent))` (lines 27-28) — only existed to enable the dead import.
3. Narrow `except Exception: pass` (lines 190-192) inside the curses event loop to `except curses.error:` — keeps tolerance for terminal-resize/draw errors but stops swallowing genuine bugs.

**Dimension**: Code Quality (CQ) — dead code and overly broad exception handling. Not derived from a tracked TD item; observed during a user question about whether the file is still in use.

**Changes Made**:
- [x] Removed unused import `from linkwatcher.logging_config import get_config_manager` (was line 30)
- [x] Removed unused `sys.path.insert(0, str(Path(__file__).parent.parent))` (was lines 27-28)
- [x] Removed now-orphaned `import sys` (natural completion of change above — `sys` had no other uses)
- [x] Narrowed `except Exception: pass` → `except curses.error: pass` in the curses event loop, with an explanatory comment

**Test Baseline** (pre-refactor, `pytest -m "not slow"`): 829 passed, 1 failed, 3 skipped, 4 deselected, 5 xfailed. Pre-existing failure: `test/automated/performance/test_large_projects.py::TestPerformanceMetrics::test_cpu_usage_monitoring`.
**Test Result** (post-refactor, same command): 829 passed, 1 failed, 3 skipped, 4 deselected, 5 xfailed. **Identical to baseline — no new failures, behavior preserved.** Smoke tests: `python tools/logging_dashboard.py --help` succeeds; `py_compile` succeeds; `ast.parse` succeeds.

**Documentation & State Updates**:
- [x] Feature implementation state file (3.1.1) updated, or **N/A** — file lists `tools/logging_dashboard.py` only with a generic description ("Log monitoring dashboard (console + text mode)") that is still accurate; no reference to the changed import or exception handler.
- [x] TDD (3.1.1) **updated** — [tdd-3-1-1-logging-framework-t2.md:281](/doc/technical/tdd/tdd-3-1-1-logging-framework-t2.md#L281) had a stale bullet stating `tools/logging_dashboard.py:30 imports get_config_manager but never invokes it`. Rewrote to: "does not import or invoke `LoggingConfigManager`; the dashboard reads log files directly and does not activate hot-reload."
- [x] Test spec (3.1.1) updated, or **N/A** — `grep` of [test-spec-3-1-1-logging-system.md](/test/specifications/feature-specs/test-spec-3-1-1-logging-system.md) for `logging_dashboard|get_config_manager|except Exception` returned zero hits.
- [x] FDD (3.1.1) updated, or **N/A** — `grep` of [fdd-3-1-1-logging-framework.md](/doc/functional-design/fdds/fdd-3-1-1-logging-framework.md) for the same patterns returned zero hits.
- [x] ADR updated, or **N/A** — no ADR directory exists in `doc/technical/architecture/`.
- [x] Integration Narrative **updated** — [configuration-change-integration-narrative.md:133](/doc/technical/integration/configuration-change-integration-narrative.md#L133) said `LoggingConfigManager` "is exercised by unit tests and `tools/logging_dashboard.py`". The dashboard never actually exercised it (only imported the name); after this refactor even the import is gone. Removed "and `tools/logging_dashboard.py`" from the parenthetical.
- [x] Validation tracking updated, or **N/A** — feature 3.1.1 in [validation-tracking-4.md:48](/doc/state-tracking/validation/validation-tracking-4.md#L48) is marked Completed with rationale "No direct changes (regression check)". The refactored code paths (dead import, blanket except in a curses TUI) are outside the scope of any tracked validation finding.
- [x] Technical Debt Tracking: **N/A** — no TD item; refactoring originated from observation in conversation, not from tracked debt.

**Bugs Discovered**: None.

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | None (observation-driven) | Complete | None | TDD-3-1-1 §LoggingConfigManager Production Status; configuration-change-integration-narrative.md §Callback/Event Chains |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
