---
id: PD-REF-175
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-09
updated: 2026-04-09
debt_item: TD188
mode: documentation-only
refactoring_scope: FDD PD-FDD-025 missing CLI vs config precedence and json_logs console scope documentation
priority: Medium
target_area: Logging Framework FDD
feature_id: 3.1.1
---

# Documentation Refactoring Plan: FDD PD-FDD-025 missing CLI vs config precedence and json_logs console scope documentation

## Overview
- **Target Area**: Logging Framework FDD
- **Priority**: Medium
- **Created**: 2026-04-09
- **Author**: AI Agent & Human Partner
- **Status**: Planning
- **Mode**: Documentation-only (no code changes, no test impact)
- **Debt Item**: TD188

## Refactoring Scope
<!-- Detailed description of what documentation will be refactored and why -->

### Current Issues
- Issue 1: FDD FR-3 says "optionally write JSON-formatted log messages to a rotating log file" — implies `json_logs` only affects file output. Actually, `json_logs` controls the structlog processor pipeline (JSONRenderer vs ConsoleRenderer) which formats ALL output including console.
- Issue 2: FDD documents both CLI `--log-file` (UI-2) and config `log_file` (dependency on 0.1.3) but never states what happens when both are set. Code at main.py:336 establishes CLI takes precedence.

### Scope Discovery
- **Original Tech Debt Description**: CLI --log-file takes priority over config.log_file but this is undocumented. Also json_logs param switches console output format (not just file) but FDD FR-3 conflates the two.
- **Actual Scope Findings**: Both issues confirmed by code analysis. json_logs controls structlog processor at logging.py:385-387. CLI precedence at main.py:336.
- **Scope Delta**: None — scope matches original description.

### Refactoring Goals
- Goal 1: Correct FR-3 to accurately describe json_logs scope (affects console format, not just file)
- Goal 2: Add precedence rule documentation for CLI vs config file log settings
- Goal 3: Add a business rule documenting json_logs as config-file-only (no CLI flag)

## Current State Analysis

### Documentation Quality Baseline
- **Accuracy**: FR-3 inaccurately describes json_logs as file-only; precedence rules absent
- **Completeness**: Missing config-source precedence and json_logs console effect
- **Cross-references**: Correct — TDD PD-TDD-024 and config system dependency are linked
- **Consistency**: Terminology is consistent; the gap is missing content, not inconsistent content

### Affected Documents
- Document 1: `doc/functional-design/fdds/fdd-3-1-1-logging-framework.md` — Update FR-3, add BR-6 (precedence), add BR-7 (json_logs config-only)

### Dependencies and Impact
- **Cross-references**: TDD PD-TDD-024 references the FDD — no changes needed there (TDD already documents json_logs correctly)
- **State files**: technical-debt-tracking.md (TD188 → Resolved), feature-tracking.md (3.1.1 status unchanged)
- **Risk Assessment**: Low — additive documentation changes, no existing content removed

## Refactoring Strategy

### Approach
Single-phase edit of the FDD with three targeted changes: fix FR-3 wording, add two new business rules.

### Implementation Plan
1. **Update FR-3**: Change "optionally write JSON-formatted log messages to a rotating log file configurable via startup arguments or config file" to accurately describe that `json_logs` switches the structlog output format for all outputs (console + file), not just file
2. **Add BR-6**: Document CLI vs config precedence chain (CLI > env > config file > defaults), noting that `--log-file` overrides `config.log_file`
3. **Add BR-7**: Document that `json_logs` is config-file-only (no CLI flag exists)

## Verification Approach
- **Link validation**: LinkWatcher running — will catch any broken references
- **Content accuracy**: Compare updated FR-3 and new BRs against main.py:325-345 and logging.py:385-387
- **Consistency check**: Verify new BRs follow existing BR numbering and formatting conventions

## Success Criteria

### Documentation Quality Improvements
- **Accuracy**: FR-3 correctly describes json_logs scope as affecting all output formats
- **Completeness**: Precedence rules and json_logs availability documented
- **Cross-references**: No new cross-references needed; existing ones preserved

### Documentation Integrity
<!-- Ensure no documentation regressions -->
- [ ] All existing cross-references preserved or updated
- [ ] No orphaned references created
- [ ] Terminology consistent with project conventions
- [ ] LinkWatcher confirms no broken links

## Implementation Tracking

### Progress Log
<!-- Track progress during implementation -->
| Date | Phase | Completed Work | Issues Encountered | Next Steps |
|------|-------|----------------|-------------------|------------|
| 2026-04-09 | Planning | Created plan PD-REF-175, verified TD188 against code | None | Implement FDD changes |
| 2026-04-09 | Implementation | Updated FR-3, added BR-6 (precedence), BR-7 (json_logs config-only) | None | State updates |

## Results

### Remaining Technical Debt
- None expected — TD188 fully addressed by this plan

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
