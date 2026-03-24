---
id: PD-REF-035
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-03
updated: 2026-03-03
refactoring_scope: Replace bare except with except Exception in database.py
priority: Medium
mode: lightweight
target_area: linkwatcher/database.py
---

# Lightweight Refactoring Plan: Replace bare except with except Exception in database.py

- **Target Area**: linkwatcher/database.py
- **Priority**: Medium
- **Created**: 2026-03-03
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (≤15 min effort, single file, no architectural impact)

## Item 1: TD019 — Replace bare `except:` with `except Exception:` in database.py

**Scope**: Replace bare `except:` on line 131 of `linkwatcher/database.py` (`_reference_points_to_file()`) with `except Exception:`. The bare except catches `SystemExit` and `KeyboardInterrupt`, which should propagate. Same pattern as already-resolved TD011 in handler.py.

**Changes Made**:
- [x] Line 131: `except:` → `except Exception:`

**Test Baseline**: 393 passed, 5 skipped, 7 xfailed, 15 warnings
**Test Result**: 393 passed, 5 skipped, 7 xfailed, 15 warnings (identical)

**Documentation & State Updates**:
- [x] Feature implementation state file updated — N/A
- [x] TDD updated — N/A (no interface/design change)
- [x] Test spec updated — N/A (no behavior change)
- [x] FDD updated — N/A (no functional change)
- [x] Technical Debt Tracking: TD019 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD019 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
