---
id: "[ID_PLACEHOLDER]"
type: Process Framework
category: State File
version: 1.0
created: "[DATE_PLACEHOLDER]"
updated: "[DATE_PLACEHOLDER]"
usage_context: Process Framework - Audit Tracking
description: Template for creating test audit tracking state files
creates_document_category: State Tracking
creates_document_prefix: PF-STA
creates_document_type: Process Framework
creates_document_version: 1.0
template_for: Audit Tracking
---

# Test Audit Tracking — [Round N]

## Purpose & Context

This file tracks the progress and results of a **Test Audit round** across all test files in scope. It provides a centralized view of which files have been audited, session planning, and cross-session continuity.

> **Task**: [Test Audit (PF-TSK-030)](/process-framework/tasks/03-testing/test-audit-task.md)

## Audit Round Overview

| Attribute | Value |
|-----------|-------|
| Round | [Round N] |
| Created | [DATE] |
| Scope | [SCOPE_DESCRIPTION] |
| Status | NOT_STARTED |

## Test File Inventory

> Auto-populated from [Test Tracking](/test/state-tracking/permanent/test-tracking.md). Each row represents a test file eligible for audit.

| # | Feature ID | Test File | Current Status | Audit Status | Report Link | Session | Notes |
|---|------------|-----------|----------------|--------------|-------------|---------|-------|
[INVENTORY_PLACEHOLDER]

### Inventory Legend

**Current Status** — from test-tracking.md:
- **Audit Approved**: Previously approved, eligible for re-audit
- **Approved — Pending Dependencies**: Previously approved with dependency caveats
- **Needs Update**: Previously audited, needs re-audit after changes

**Audit Status** — updated during this round:
- **Pending**: Not yet audited in this round
- **In Progress**: Audit session active
- **Done**: Audit complete — see Report Link
- **Skipped**: Excluded from this round (provide reason in Notes)

## Progress Summary

| Metric | Count |
|--------|-------|
| Total files in scope | [TOTAL] |
| Audited | 0 |
| Pending | [TOTAL] |
| Skipped | 0 |

## Session Planning

### Recommended Session Sequence

> Group test files by feature for efficient context loading. Aim for 1-3 test files per session depending on complexity.

1. **Session 1**: [Feature Group] — [Test files] ([Rationale])
2. **Session 2**: [Feature Group] — [Test files] ([Rationale])

### Session Log

| Session | Date | Files Audited | Outcomes | Notes |
|---------|------|---------------|----------|-------|
| 1 | — | — | — | — |

## Cross-References

- **Test Tracking**: [Test Tracking](/test/state-tracking/permanent/test-tracking.md) — source of truth for test file status
- **Feature Tracking**: [Feature Tracking](/doc/state-tracking/permanent/feature-tracking.md) — aggregated feature-level test status
- **Technical Debt**: [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md) — for significant audit findings

## Change Log

### [DATE]

- **Created**: Initial audit tracking file for [Round N]
- **Status**: Ready for audit sessions
- **Scope**: [SCOPE_DESCRIPTION]
