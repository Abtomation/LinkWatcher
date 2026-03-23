---
id: PF-REF-037
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-03
updated: 2026-03-03
refactoring_scope: Remove inline import re in updater.py
priority: Medium
mode: lightweight
target_area: linkwatcher/updater.py
---

# Lightweight Refactoring Plan: Remove inline import re in updater.py

- **Target Area**: linkwatcher/updater.py
- **Priority**: Medium
- **Created**: 2026-03-03
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (≤15 min effort, single file, no architectural impact)

## Item 1: TD025 — Remove inline `import re` in updater.py

**Scope**: Add `import re` at module level and remove the 2 inline `import re` statements in `_replace_markdown_target()` (line 476) and `_replace_reference_target()` (line 504). Note: TD025 description states "Module-level import already exists" but this is incorrect — `re` is only imported inline. The fix adds the module-level import and removes both inline occurrences. Same pattern as resolved TD012/TD014 in handler.py.

**Changes Made**:
- [x] Add `import re` at module level (line 9, after `import os`)
- [x] Remove `import re` from `_replace_markdown_target()` (was line 476)
- [x] Remove `import re` from `_replace_reference_target()` (was line 504)

**Test Baseline**: 393 passed, 5 skipped, 7 xfailed, 15 warnings
**Test Result**: 383 passed, 5 skipped, 7 xfailed (with TD024 Enum test class deselected — 5 failures are from concurrent TD024 work, not this change)

**Documentation & State Updates**:
- [x] Feature implementation state file updated — N/A
- [x] TDD updated — N/A (no interface/design change)
- [x] Test spec updated — N/A (no behavior change)
- [x] FDD updated — N/A (no functional change)
- [x] Technical Debt Tracking: TD025 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None. TD025 description inaccuracy noted: stated "Module-level import already exists" but `re` was only imported inline. Corrected in scope description above.

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD025 | Complete | None | TD025 description corrected |

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
