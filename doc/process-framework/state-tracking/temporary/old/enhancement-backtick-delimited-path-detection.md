---
id: PF-STA-057
type: Process Framework
category: State Tracking
version: 1.0
created: 2026-03-16
updated: 2026-03-16
enhancement_name: backtick-delimited-path-detection
target_feature: 2.1.1
---

# Enhancement State Tracking: Backtick-Delimited Path Detection

> **TEMPORARY FILE**: This file tracks enhancement work on an existing feature. Created by Feature Request Evaluation (PF-TSK-067), consumed by Feature Enhancement (PF-TSK-068). Move to `state-tracking/temporary/old/` when all steps are complete.

## Enhancement Overview

| Metadata | Value |
|----------|-------|
| **Target Feature** | 2.1.1 — Link Parsing System |
| **Secondary Features Affected** | None |
| **Enhancement Description** | Extend markdown parser quoted patterns to recognize backtick-delimited paths (`` `path/to/file` ``) as file and directory references, enabling LinkWatcher to update them during file/directory moves |
| **Change Request** | After moving the validation directory, paths inside backticks in markdown files were not updated. The markdown parser's `quoted_pattern` and `quoted_dir_pattern` regexes only match single/double quotes, not backticks. |
| **Human Approval** | 2026-03-16 — Target feature confirmed by human partner |
| **Estimated Sessions** | 1 |
| **Created By** | Feature Request Evaluation (PF-TSK-067) |

## Scope Assessment

| Criterion | Assessment |
|-----------|------------|
| **Files Affected** | 2-3 source files (`parsers/markdown.py`, possibly `parsers/generic.py`), 1-2 test files (`test/automated/parsers/test_markdown.py`, possibly `test/automated/parsers/test_generic.py`) |
| **Design Docs to Amend** | TDD (PD-TDD-025) — parser patterns section; FDD (PD-FDD-026) — supported link syntax description |
| **New Tests Required** | Yes — backtick-delimited file paths and directory paths in markdown content |
| **Interface Impact** | Internal only — no public API change, same `LinkReference` output |
| **Session Estimate** | Single session — small regex change + test additions |

## Existing Documentation Inventory

| Document Type | ID | Location | Action Needed |
|---------------|-----|----------|---------------|
| Feature State File | PF-FEA-050 | [2.1.1-link-parsing-system-implementation-state.md](../../../../product-docs/state-tracking/features/2.1.1-link-parsing-system-implementation-state.md) | Update on completion |
| FDD | PD-FDD-026 | [fdd-2-1-1-parser-framework.md](../../../../product-docs/functional-design/fdds/fdd-2-1-1-parser-framework.md) | Amend — update supported link syntax to include backtick-delimited paths |
| TDD | PD-TDD-025 | [tdd-2-1-1-parser-framework-t2.md](../../../../product-docs/technical/architecture/design-docs/tdd/tdd-2-1-1-parser-framework-t2.md) | Amend — update MarkdownParser pattern descriptions |
| ADR | N/A | N/A | No change |
| Test Specification | PF-TSP-039 | [test-spec-2-1-1-link-parsing-system.md](../../../../../test/specifications/feature-specs/test-spec-2-1-1-link-parsing-system.md) | No change — enhancement doesn't alter test methodology |

## Execution Steps

> **Structure**: These steps follow the standard feature development workflow from the [Task Transition Guide](../../../guides/framework/task-transition-guide.md). Each block corresponds to a task type in the workflow. The Feature Request Evaluation task (PF-TSK-067) marks each block as **Applicable** or **Not applicable** based on the enhancement scope. The Feature Enhancement task (PF-TSK-068) executes applicable blocks in order.

---

### Step 1: Tier Reassessment

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Documentation Tier Adjustment (PF-TSK-011)](../../../tasks/cyclical/documentation-tier-adjustment-task.md)
- **Rationale**: Adding backtick support to existing regex patterns is a minor extension. Feature remains Tier 2.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 2: FDD Amendment

- **Status**: [x] Complete
- **Applicable**: Yes
- **Referenced Task Doc**: [FDD Creation (PF-TSK-010)](../../../tasks/02-design/fdd-creation-task.md)
- **Rationale**: The FDD describes supported link syntax per parser. Backtick-delimited paths are a new recognized syntax that should be documented.
- **Adaptation Notes**: Amend PD-FDD-026 MarkdownParser section to list backtick-delimited file and directory paths as a supported reference type alongside existing quoted-path patterns.
- **Deliverable**: Updated FDD with backtick syntax in MarkdownParser supported formats
- **Session**: 1

---

### Step 3: System Architecture Review

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [System Architecture Review (PF-TSK-019)](../../../tasks/01-planning/system-architecture-review.md)
- **Rationale**: Enhancement works within existing parser architecture — adding a character to regex patterns.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 4: API Design Amendment

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [API Design (PF-TSK-020)](../../../tasks/02-design/api-design-task.md)
- **Rationale**: No API involved — parser is used internally.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 5: Database Schema Design Amendment

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Database Schema Design (PF-TSK-021)](../../../tasks/02-design/database-schema-design-task.md)
- **Rationale**: No database schema changes required.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 6: TDD Amendment

- **Status**: [x] Complete
- **Applicable**: Yes
- **Referenced Task Doc**: [TDD Creation (PF-TSK-022)](../../../tasks/02-design/tdd-creation-task.md)
- **Rationale**: The TDD documents MarkdownParser's regex patterns. Adding backtick support changes the pattern definitions.
- **Adaptation Notes**: Amend PD-TDD-025 MarkdownParser section to update `quoted_pattern` and `quoted_dir_pattern` descriptions to include backtick as a recognized delimiter alongside single/double quotes.
- **Deliverable**: Updated TDD with backtick delimiter in pattern descriptions
- **Session**: 1

---

### Step 7: Test Specification

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Test Specification Creation (PF-TSK-016)](../../../tasks/03-testing/test-specification-creation-task.md)
- **Rationale**: Feature is Tier 2 — test specification exists but does not need formal amendment for this minor pattern extension. Test cases will be defined in Step 15.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 8: Feature Implementation Planning

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Feature Implementation Planning (PF-TSK-044)](../../../tasks/04-implementation/feature-implementation-planning-task.md)
- **Rationale**: Enhancement is straightforward — extend regex character class. No planning needed.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 9: Data Layer Implementation

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Data Layer Implementation (PF-TSK-051)](../../../tasks/04-implementation/data-layer-implementation.md)
- **Rationale**: No data model changes required.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

---

### Step 12: Integration & Testing

- **Status**: [x] Complete
- **Applicable**: Yes
- **Referenced Task Doc**: [Integration & Testing (PF-TSK-053)](../../../tasks/04-implementation/integration-and-testing.md)
- **Rationale**: Need to verify backtick-delimited paths are correctly detected by the parser AND correctly updated by the updater during actual file/directory moves.
- **Adaptation Notes**: Implement the regex changes in `parsers/markdown.py`: extend `quoted_pattern` and `quoted_dir_pattern` to include backtick (`` ` ``) as a delimiter. Consider also extending `parsers/generic.py` for consistency. Run existing test suite to ensure no regressions.
- **Deliverable**: Updated parser code, all existing tests passing
- **Session**: 1

---

### Step 13: Quality Validation

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Quality Validation (PF-TSK-054)](../../../tasks/04-implementation/quality-validation.md)
- **Rationale**: Minor regex change — code review suffices.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 14: Implementation Finalization

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Implementation Finalization (PF-TSK-055)](../../../tasks/04-implementation/implementation-finalization.md)
- **Rationale**: Single-session enhancement, no finalization needed.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 15: Update Tests

- **Status**: [x] Complete
- **Applicable**: Yes
- **Referenced Task Doc**: [Integration & Testing (PF-TSK-053)](../../../tasks/04-implementation/integration-and-testing.md)
- **Rationale**: New syntax needs test coverage to prevent regressions.
- **Adaptation Notes**: Add test cases to `test/automated/parsers/test_markdown.py`: (1) backtick-delimited file path (`` `path/to/file.md` ``), (2) backtick-delimited directory path (`` `path/to/directory/` ``), (3) backtick path should not overlap with markdown links, (4) mixed backtick and quote paths in same line.
- **Deliverable**: New test cases in test_markdown.py covering backtick-delimited paths
- **Session**: 1

---

### Step 16: Code Review

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Code Review (PF-TSK-005)](../../../tasks/06-maintenance/code-review-task.md)
- **Rationale**: Trivial regex change — adding one character to a character class. No separate code review warranted.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 17: Update Feature State

- **Status**: [x] Complete
- **Applicable**: Yes
- **Referenced Task Doc**: N/A — direct state file update
- **Rationale**: Feature state must always be updated to reflect the enhancement
- **Adaptation Notes**: Update 2.1.1 implementation state file (PF-FEA-050) to document backtick-delimited path detection enhancement in the Enhancement Log and Resolved Issues sections.
- **Deliverable**: Updated feature implementation state file
- **Session**: 1

---

## Session Log

### Session 1: [YYYY-MM-DD]

**Completed**:
- [List completed steps]

**Issues**:
- [Any issues encountered]

## Finalization Checklist

> **Instructions**: Complete when all applicable execution steps are done. This checklist is part of the Feature Enhancement task (PF-TSK-068) completion process.

- [ ] All applicable execution steps marked complete
- [ ] All non-applicable steps confirmed as "Not applicable" with rationale
- [ ] Target feature's implementation state file updated to reflect enhancement
- [ ] Feature tracking status restored (removed "🔄 Needs Revision", set appropriate status, removed state file link)
- [ ] This file archived to `state-tracking/temporary/old/`
