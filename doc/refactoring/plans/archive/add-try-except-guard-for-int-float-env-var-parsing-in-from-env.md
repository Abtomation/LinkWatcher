---
id: PD-REF-109
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-27
updated: 2026-03-27
mode: lightweight
refactoring_scope: Add try/except guard for int/float env var parsing in from_env()
target_area: src/linkwatcher/config/settings.py
priority: Medium
---

# Lightweight Refactoring Plan: Add try/except guard for int/float env var parsing in from_env()

- **Target Area**: src/linkwatcher/config/settings.py
- **Priority**: Medium
- **Created**: 2026-03-27
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD110 — Add try/except guard for int/float env var parsing in from_env()

**Scope**: `from_env()` calls `int(value)` and `float(value)` on raw environment variable strings without error handling. A malformed value (e.g., `LINKWATCHER_MAX_FILE_SIZE_MB=abc`) raises an uncaught `ValueError`. Fix: wrap int/float conversions in try/except, log a warning with field name and bad value, skip the field (keep default).

**Changes Made**:
- [x] Wrap `int(value)` conversion in try/except ValueError with warning log
- [x] Wrap `float(value)` conversion in try/except ValueError with warning log

**Test Baseline**: 596 passed, 5 skipped, 7 xfailed
**Test Result**: 596 passed, 5 skipped, 7 xfailed

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.3) updated, or N/A — _N/A: state file only lists `from_env()` as a capability; internal error handling doesn't change the capability description_
- [x] TDD (0.1.3) updated, or N/A — _N/A: 0.1.3 is Tier 1, no TDD exists_
- [x] Test spec (0.1.3) updated, or N/A — _N/A: grepped test-spec-0-1-3; from_env tests cover valid inputs only; graceful handling of invalid inputs is new defensive behavior, not a behavior change to existing spec_
- [x] FDD (0.1.3) updated, or N/A — _N/A: 0.1.3 is Tier 1, no FDD exists_
- [x] ADR (0.1.3) updated, or N/A — _N/A: grepped ADR directory — no ADR references from_env or env var parsing_
- [x] Validation tracking updated, or N/A — _N/A: change doesn't affect validation dimensions; it resolves the finding from PD-VAL-056_
- [x] Technical Debt Tracking: TD110 marked resolved

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD110 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
