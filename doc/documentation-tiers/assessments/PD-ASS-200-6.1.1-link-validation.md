---
id: PD-ASS-200
type: Artifact
category: Assessment
version: 1.0
created: 2026-03-16
updated: 2026-03-16
feature_id: 6.1.1
---

# Documentation Tier Assessment: Link Validation

**Assessment ID**: ART-ASS-200
**Feature ID**: 6.1.1
**Assessment Date**: 2026-03-16
**Assessed By**: AI Assistant & Human Partner

## Feature Description

On-demand workspace scanner that checks all existing links across all supported file formats (Markdown, YAML, JSON, Python, Dart, PowerShell, generic) and reports broken references — targets that no longer exist on disk. Reuses existing parser infrastructure (2.1.1) and path utilities (0.1.1).

## Complexity Assessment

| Factor                | Weight | Score | Weighted Score | Justification                                                                                     |
| --------------------- | ------ | ----- | -------------- | ------------------------------------------------------------------------------------------------- |
| **Scope**             | 0.8    | 2     | 1.6            | Touches parsers (reuse), path resolution (reuse), and a new validation module                     |
| **State Management**  | 1.2    | 1     | 1.2            | Simple collect-and-report pattern, no persistent state needed                                     |
| **Data Flow**         | 1.5    | 2     | 3.0            | Scan files → parse links → resolve paths → check existence → report                              |
| **Business Logic**    | 2.5    | 2     | 5.0            | Link resolution across file types, relative path handling, anchor handling, different link formats |
| **UI Complexity**     | 0.5    | 1     | 0.5            | CLI text output only — no UI components                                                           |
| **API Integration**   | 1.5    | 1     | 1.5            | No external APIs — local file system operations only                                              |
| **Database Changes**  | 1.2    | 1     | 1.2            | No schema changes — can leverage existing in-memory DB or scan directly                           |
| **Security Concerns** | 2.0    | 1     | 2.0            | No security implications — read-only file system operations                                       |
| **New Technologies**  | 1.0    | 1     | 1.0            | Uses existing Python/pathlib, no new dependencies                                                 |

**Sum of Weighted Scores**: 17.0
**Sum of Weights**: 12.2
**Normalized Score**: 1.39

## Design Requirements Evaluation

### UI Design Required

- [x] No - Pure CLI tool with text output. No user interface components.

### API Design Required

- [x] No - Internal feature with no API endpoints. Invoked via CLI flag or function call.

### Database Design Required

- [x] No - Read-only operations against existing link database or direct file scanning. No schema changes.

## Documentation Tier Assignment

- [x] Tier 1 (Simple) 🔵 (1.0-1.6)
- [ ] Tier 2 (Moderate) 🟠 (1.61-2.3)
- [ ] Tier 3 (Complex) 🔴 (2.31-3.0)

## Rationale

Link Validation scores 1.39, firmly in Tier 1. The feature heavily reuses existing infrastructure — parsers from 2.1.1 and path utilities from 0.1.1. The core logic is straightforward: iterate files, extract links, resolve paths, check existence, report. No persistent state, no UI, no APIs, no security concerns. The main complexity is in correctly resolving different link formats across file types, but that logic already exists in the parser system.

## Special Considerations

- Depends on parser infrastructure (2.1.1) — reuses existing parsers without modification
- Depends on path utilities (0.1.1) — reuses existing path resolution
- Read-only operation — no risk of data corruption or unintended side effects
- Performance may be a consideration for very large workspaces, but not a documentation concern

## Implementation Notes

- Consider adding a `--validate` CLI flag to `main.py` for on-demand invocation
- Output format should include source file, line number, broken link target, and link type
- Could optionally leverage the existing `LinkDatabase` if populated, or scan fresh
- Consider exit code semantics (0 = no broken links, 1 = broken links found) for CI integration
