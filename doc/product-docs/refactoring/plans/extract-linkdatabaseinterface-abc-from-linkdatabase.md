---
id: PD-REF-073
type: Document
category: General
version: 1.0
created: 2026-03-17
updated: 2026-03-17
refactoring_scope: Extract LinkDatabaseInterface ABC from LinkDatabase
debt_item: TD058
priority: Medium
target_area: database.py, handler.py, reference_lookup.py, service.py, dir_move_detector.py
---

# Refactoring Plan: Extract LinkDatabaseInterface ABC from LinkDatabase

## Overview
- **Target Area**: database.py, handler.py, reference_lookup.py, service.py, __init__.py
- **Priority**: Medium
- **Created**: 2026-03-17
- **Author**: AI Agent & Human Partner
- **Status**: Completed
- **Debt Item**: TD058

## Refactoring Scope

### Current Issues
- LinkDatabase is a concrete class with no abstract interface
- All consumers import and type-hint against the concrete class
- Cannot swap storage backends without refactoring all consumers

### Scope Discovery
- **Original Tech Debt Description**: Concrete class only; no LinkDatabaseInterface ABC. Cannot swap for persistent storage without refactoring all consumers.
- **Actual Scope Findings**: Matched original. 10 public methods used by consumers, plus `last_scan` attribute. No direct attribute access of `links` or `files_with_links` from consumers (already encapsulated via public methods from TD006).
- **Scope Delta**: None

### Refactoring Goals
- Define LinkDatabaseInterface ABC with all public methods as abstract
- Make LinkDatabase inherit from the ABC
- Update consumer type hints to use the interface
- Convert `last_scan` from plain attribute to abstract property

## Affected Components
- `linkwatcher/database.py` — ABC definition + LinkDatabase inheritance + last_scan property
- `linkwatcher/handler.py` — Type hint update
- `linkwatcher/reference_lookup.py` — Type hint update
- `linkwatcher/service.py` — Added interface import
- `linkwatcher/__init__.py` — Export ABC

## Results

### Changes Made
- `database.py`: Added `LinkDatabaseInterface(ABC)` with 10 abstract methods + `last_scan` abstract property. `LinkDatabase` inherits from it. `last_scan` converted from plain attribute to property backed by `_last_scan`.
- `handler.py`: Import and type hint changed from `LinkDatabase` to `LinkDatabaseInterface`
- `reference_lookup.py`: Same type hint change
- `service.py`: Added `LinkDatabaseInterface` import (keeps `LinkDatabase` for instantiation)
- `__init__.py`: Added `LinkDatabaseInterface` to exports
- `test_database.py`: 4 new tests — subclass check, isinstance check, direct instantiation fails, incomplete implementation fails

### Test Results
- **Baseline**: 457 passed
- **Final**: 465 passed (+4 ABC tests, +4 from parallel session additions), 1 pre-existing failure from uncommitted parallel session test
- **Regressions**: None

### Bugs Discovered
None.

### Remaining Technical Debt
None related to this scope.

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
- [ADR-040: Target-Indexed In-Memory Link Database](/doc/product-docs/technical/architecture/design-docs/adr/adr/target-indexed-in-memory-link-database.md)
