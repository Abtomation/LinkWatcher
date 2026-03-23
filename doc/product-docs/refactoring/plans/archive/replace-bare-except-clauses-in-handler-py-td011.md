---
id: PF-REF-024
type: Document
category: General
version: 1.0
created: 2026-03-02
updated: 2026-03-02
priority: Medium
refactoring_scope: Replace Bare Except Clauses in handler.py (TD011)
target_area: linkwatcher/handler.py
---

# Refactoring Plan: Replace Bare Except Clauses in handler.py (TD011)

## Overview
- **Target Area**: linkwatcher/handler.py
- **Priority**: Medium
- **Created**: 2026-03-02
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Assessment**: [PF-TDA-001](../../assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md)
- **Debt Item**: PF-TDI-007

## Refactoring Scope

### Current Issues

Two bare `except:` clauses catch **all** exceptions including `SystemExit`, `KeyboardInterrupt`, and `GeneratorExit`, which should never be silently swallowed:

1. **Line 503** (`on_deleted` method): Bare `except:` when getting file size of a deleted file
2. **Line 650** (`_detect_move_from_create` method): Bare `except:` when getting file size of a created file

Both are guarding `os.path.getsize()` calls where only `OSError` (file not found, permission denied, etc.) is expected.

### Refactoring Goals

- Replace `except:` with `except Exception:` to avoid catching `SystemExit`/`KeyboardInterrupt`
- Maintain identical external behavior for all normal exception cases

## Current State Analysis

### Code Quality Metrics (Baseline)

- **Bare except count**: 2 instances
- **Test Suite Baseline**: 344 passed, 9 failed (pre-existing), 4 skipped, 21 xfailed, 1 xpassed
- **Technical Debt**: TD011 open (Medium priority, <15 min effort)

### Affected Components

- `linkwatcher/handler.py:503` — `on_deleted` method
- `linkwatcher/handler.py:650` — `_detect_move_from_create` method

### Dependencies and Impact

- **Internal Dependencies**: Both methods are called during file event processing (move detection pipeline)
- **External Dependencies**: None — only `os.path.getsize()` is called
- **Risk Assessment**: Very Low — changing `except:` to `except Exception:` is a narrowing of catch scope; all `OSError`/`IOError` exceptions (the only realistic errors from `os.path.getsize`) are subclasses of `Exception`

## Refactoring Strategy

### Approach

Direct replacement of `except:` with `except Exception:` at both locations. No logic changes.

### Implementation Plan

1. Replace `except:` at line 503 with `except Exception:`
2. Replace `except:` at line 650 with `except Exception:`
3. Run full test suite to confirm no regressions

## Testing Strategy

### Existing Test Coverage

- `tests/test_move_detection.py` — covers move detection pipeline
- `tests/test_directory_move_detection.py` — covers directory move detection
- `tests/integration/` — integration tests for file events

### Testing Approach

- Run full test suite before and after to compare results
- No new tests needed — this is a narrowing change that preserves all normal behavior

## Success Criteria

- [x] Zero bare `except:` clauses remaining in handler.py
- [x] All existing tests continue to pass (same 344 passed)
- [x] No new test failures introduced

## Implementation Tracking

| Date | Phase | Completed Work | Issues Encountered | Next Steps |
|------|-------|----------------|-------------------|------------|
| 2026-03-02 | Planning | Analysis complete, plan created | None | Implement changes |
| 2026-03-02 | Execution | Replaced 2 bare except: with except Exception: | None | Validate |
| 2026-03-02 | Validation | Tests: 344 passed, 9 failed (same as baseline). Zero bare except: remaining. | None | Complete |

## Results and Lessons Learned

- **Bare except count**: 2 → 0
- **Test results**: Identical before/after (344 passed, 9 failed pre-existing)
- **Bug discovery**: No bugs discovered during this refactoring. The scope was too narrow (2 single-line changes) to expose hidden issues.
- **Status**: Complete

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
- [Handler Module Structural Debt Assessment](/doc/process-framework/assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md)
