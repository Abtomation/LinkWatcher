---
id: PD-REF-122
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-28
updated: 2026-03-28
refactoring_scope: Document per-parser config enable/disable flags in TDD and FDD
mode: documentation-only
priority: Medium
target_area: Parser Framework Documentation
---

# Documentation Refactoring Plan: Document per-parser config enable/disable flags in TDD and FDD

## Overview
- **Target Area**: Parser Framework Documentation
- **Priority**: Medium
- **Created**: 2026-03-28
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Documentation-only (no code changes, no test impact)

## Item 1: TD123 — Document per-parser config enable/disable flags in TDD and FDD

**Scope**: `LinkWatcherConfig` defines 7 `enable_<format>_parser` boolean flags (settings.py:91-97) that control which parsers are registered at `LinkParser.__init__()` (parser.py:36-54). Neither TDD PD-TDD-025 nor FDD PD-FDD-026 mention these configuration flags. The TDD describes the component architecture as unconditional pre-instantiation, and the FDD says "zero configuration for standard file types" without noting that parsers can be individually disabled.

**Changes Made**:
- [x] TDD §4.1 Decision 1: Added Configuration note documenting conditional registration gated by `config.enable_<format>_parser` flags
- [x] TDD §2 Key Requirements: Updated requirement 3 to note conditional pre-instantiation
- [x] TDD §3.4 Usability: Added per-parser enable flags mention alongside "zero configuration" statement
- [x] FDD BR-2: Added cross-reference to BR-7 noting conditional registration
- [x] FDD BR-7: Added new business rule documenting all 7 enable flags, defaults, and GenericParser disable behavior

**Documentation & State Updates**:
- [x] Technical Debt Tracking: TD123 marked resolved via Update-TechDebt.ps1

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
