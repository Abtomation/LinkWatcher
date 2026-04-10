---
id: PD-REF-174
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-09
updated: 2026-04-09
feature_id: 0.1.1
target_area: Core Architecture TDD
priority: Medium
mode: documentation-only
debt_item: TD190
refactoring_scope: Document --validate CLI mode and LinkValidator integration in TDD-0-1-1
---

# Documentation Refactoring Plan: Document --validate CLI mode and LinkValidator integration in TDD-0-1-1

## Overview
- **Target Area**: Core Architecture TDD
- **Priority**: Medium
- **Created**: 2026-04-09
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Documentation-only (no code changes, no test impact)
- **Debt Item**: TD190

## Refactoring Scope

TDD-0-1-1 (Core Architecture) Section 4.4 documents main.py's CLI entry point but omits the `--validate` operational mode entirely. This mode was added on 2026-03-24 as part of feature 6.1.1 (Link Validation, Tier 1). Because 6.1.1 is Tier 1, no separate TDD was created — but the existing TDD for 0.1.1 that documents main.py was not updated either.

### Current Issues

- Issue 1: Section 4.4 CLI pseudocode missing `--validate` argument
- Issue 2: No documentation of the validation operational mode (scan-and-exit vs live-watch)
- Issue 3: LinkValidator not mentioned in component diagram or key source files

### Scope Discovery

- **Original Tech Debt Description**: "TDD-0-1-1 does not document --validate CLI flag or LinkValidator integration in main.py (entire operational mode undocumented)"
- **Actual Scope Findings**: Confirmed accurate. Section 4.4 shows only the watcher path. Section 3.1 component diagram and Section 11.2 key source files also omit validator.py.
- **Scope Delta**: Slightly broader — component diagram (3.1) and key source files (11.2) also need minor additions beyond just Section 4.4.

### Refactoring Goals

- Goal 1: Document `--validate` CLI flag in Section 4.4 pseudocode
- Goal 2: Document the validation operational mode flow (scan → report → exit)
- Goal 3: Add validator.py to key source files list (Section 11.2)

## Current State Analysis

### Documentation Quality Baseline

- **Accuracy**: Section 4.4 accurately documents the watcher mode but is incomplete — omits the validation mode entirely
- **Completeness**: Missing an entire operational mode (`--validate`). Component diagram (3.1) missing validator.py. Key source files (11.2) missing validator.py.
- **Cross-references**: Existing cross-references are correct; no broken links
- **Consistency**: TDD formatting and style are consistent; new content will follow existing conventions

### Affected Documents

- Document 1: `doc/technical/tdd/tdd-0-1-1-core-architecture-t3.md` — Add --validate to Section 4.4 CLI pseudocode, add validator.py to Section 11.2 key source files

### Dependencies and Impact

- **Cross-references**: No documents reference Section 4.4 pseudocode directly
- **State files**: Technical debt tracking (TD-190 → Resolved)
- **Risk Assessment**: Low — additive documentation changes only, no existing content modified

## Refactoring Strategy

### Approach

Additive changes to TDD-0-1-1. No existing content is removed or rewritten — only new sections/lines added.

### Implementation Plan

1. **Phase 1**: Update Section 4.4 CLI Entry Point
   - Step 1.1: Add `--validate` to the argparse pseudocode block
   - Step 1.2: Add validation mode flow after the argparse block showing the scan-and-exit path

2. **Phase 2**: Update Section 11.2 Key Source Files
   - Step 2.1: Add `linkwatcher/validator.py` with description

## Verification Approach

- **Link validation**: LinkWatcher running in background; will catch any broken links
- **Content accuracy**: Compare added pseudocode against actual main.py lines 268-314 and validator.py class interface
- **Consistency check**: Match existing TDD formatting conventions (pseudocode style, section structure)

## Success Criteria

### Documentation Quality Improvements

- **Accuracy**: Section 4.4 pseudocode reflects both operational modes (watcher and validation)
- **Completeness**: All main.py CLI arguments documented; validator.py listed in key source files
- **Cross-references**: Zero broken links in affected document

### Documentation Integrity

- [x] All existing cross-references preserved or updated
- [x] No orphaned references created
- [x] Terminology consistent with project conventions
- [x] LinkWatcher confirms no broken links

## Implementation Tracking

### Progress Log

| Date | Phase | Completed Work | Issues Encountered | Next Steps |
|------|-------|----------------|-------------------|------------|
| 2026-04-09 | Planning | Refactoring plan created, scope verified | None | Implement TDD updates |
| 2026-04-09 | Implementation | Updated TDD-0-1-1 Section 4.4 (--validate pseudocode + explanation) and Section 11.2 (added validator.py). TD-190 resolved via Update-TechDebt.ps1. Created PF-IMP-432 for cross-TDD check gap. | None | Archive plan |

## Results

### Remaining Technical Debt

- None — TD-190 fully resolved by this change

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
- [TDD-0-1-1 Core Architecture](/doc/technical/tdd/tdd-0-1-1-core-architecture-t3.md)
