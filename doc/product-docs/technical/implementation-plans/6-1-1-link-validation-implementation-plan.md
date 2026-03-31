---
id: PD-IMP-002
type: Document
category: General
version: 1.0
created: 2026-03-24
updated: 2026-03-24
feature_name: 6.1.1-link-validation
status: Planning
---

# 6.1.1 Link Validation - Implementation Plan

## Executive Summary

On-demand workspace scanner that checks all existing links across all supported file formats and reports broken references — targets that no longer exist on disk. Reuses existing parser infrastructure (2.1.1) and path utilities (0.1.1). Read-only operation with no risk of data corruption.

**Key Metrics:**
- Estimated implementation duration: 4-8 hours across 3 phases
- Team size required: 1 AI agent + human partner
- Complexity level: Low (Tier 1, score 1.39)
- Risk level: Low

## Feature Overview

### Purpose and Goals

- **Primary user goal**: Confidence that all cross-references in the workspace are valid, especially after bulk operations or when starting to use LinkWatcher on an existing project
- **Business objective**: Complete link health visibility with a single command
- **Success criteria**: All broken links in workspace detected and reported with file location and line number

### Requirements Summary

- **Functional Requirements**:
  - Scan all files matching LinkWatcher's configured file extensions
  - Extract links using existing parsers
  - Resolve relative paths and check if targets exist on disk
  - Report broken links with source file, line number, and target path
  - Write report to `LinkWatcherBrokenLinks.txt` in the run directory
  - CLI invocation via `python main.py --validate`
  - Exit code: 0 = no broken links, 1 = broken links found (CI-friendly)
- **Non-Functional Requirements**: Performance comparable to existing `_initial_scan()` (handles 1000+ files)
- **Constraints**: Read-only operation, no file modifications, no database mutations

### Scope Boundaries

**In scope**: Local file reference validation, text report output, CLI integration

**Out of scope**: URL validation (HTTP/HTTPS), auto-fix broken links, JSON/structured output, integration with real-time watcher

## Architecture and Design

### System Integration

This feature adds a single new module and modifies the CLI entry point. No changes to existing components.

**Components reused (no modification):**

| Component | Used For | Methods/APIs |
|-----------|----------|--------------|
| `linkwatcher/parser.py` → `LinkParser` | Parse files to extract link references | `parse_file(file_path) → List[LinkReference]` |
| `linkwatcher/utils.py` | File filtering and path utilities | `should_monitor_file()`, `normalize_path()`, `looks_like_file_path()`, `safe_file_read()` |
| `linkwatcher/models.py` → `LinkReference` | Link data structure | `file_path`, `line_number`, `link_target`, `link_type` |
| `linkwatcher/config/` | Configuration (extensions, ignored dirs) | `monitored_extensions`, `ignored_directories` |

**Pattern reused**: `LinkWatcherService._initial_scan()` ([service.py:143-177](../../../../linkwatcher/service.py#L143-L177)) — same walk + parse pattern, different post-processing.

### Data Flow

```
Walk monitored files (os.walk + should_monitor_file)
  → Parse each file (LinkParser.parse_file)
    → For each LinkReference:
        → Filter: skip URLs, python-imports
        → Strip anchor (#section)
        → Resolve relative target against source file directory
        → Check os.path.exists()
        → If broken: collect BrokenLink(file, line, target, type)
  → Generate report (console + file)
  → Return exit code
```

## Implementation Approach

### Phase Breakdown

**Phase 1: Core Validation Module** — Effort: S (1-3 hours)

| Action | File | Details |
|--------|------|---------|
| Create | `linkwatcher/validator.py` | `LinkValidator` class, `ValidationResult` and `BrokenLink` dataclasses |

Deliverables:
- `BrokenLink` dataclass: source file, line number, target path, link type
- `ValidationResult` dataclass: list of `BrokenLink`, scan stats (files scanned, links checked)
- `LinkValidator(project_root, config)`: accepts same config as service
- `validate() → ValidationResult`: main entry, walks files → parses → resolves → checks
- `format_report(result) → str`: generates human-readable text report
- `write_report(result, output_dir)`: writes `LinkWatcherBrokenLinks.txt`

Dependencies: None (reuses existing modules without modification)

**Phase 2: CLI Integration** — Effort: S (< 1 hour)

| Action | File | Details |
|--------|------|---------|
| Modify | `main.py` | Add `--validate` argument, early-exit branch before service startup |

Deliverables:
- `--validate` flag in argparse
- Early-exit branch: validate → print → write file → `sys.exit(0 or 1)`
- Does NOT acquire lock file, does NOT start watcher
- Respects `--config`, `--project-root`, `--quiet`, `--log-file`

Dependencies: Phase 1 (validator module must exist)

**Phase 3: Testing** — Effort: S (2-3 hours)

| Action | File | Details |
|--------|------|---------|
| Create | `test/automated/unit/test_validator.py` | Unit tests for `LinkValidator` |

Dependencies: Phase 1 and 2 complete

### Task Sequencing

```
Phase 1 (validator.py)  →  Phase 2 (main.py)  →  Phase 3 (tests)
```

Strictly sequential — each phase builds on the prior.

### Technical Approach

- **File walking**: `os.walk()` with `should_monitor_file()` filter (same as `_initial_scan()`)
- **Link extraction**: `LinkParser(config).parse_file()` — delegates to format-specific parsers
- **Target resolution**: `os.path.join(source_dir, target)` → `os.path.normpath()` → `os.path.exists()`
- **Anchor handling**: Strip `#...` suffix before existence check
- **URL filtering**: Skip targets starting with `http://`, `https://`, `ftp://`, `mailto:`, `tel:`, `data:`
- **Python imports**: Skip `link_type == "python-import"` (module paths, not file paths)
- **Output file location**: Derive from `--log-file` parent dir → `config.log_file` parent dir → project root

## Dependencies and Integration

### Internal Dependencies

| Feature | Status | Used For | Impact if unavailable |
|---------|--------|----------|----------------------|
| 0.1.1 Core Architecture | 🟢 Completed | Path utilities, data models | Cannot resolve link paths |
| 2.1.1 Link Parsing System | 🟢 Completed (code) | Parser facade + 7 format parsers | Would need to reimplement link extraction |
| 0.1.3 Configuration System | 🟢 Completed | monitored_extensions, ignored_directories | Cannot filter files correctly |

### External Dependencies

None — local file system operations only, no new packages required.

### Integration Points

- **Config system**: Reuses `LinkWatcherConfig.monitored_extensions` and `ignored_directories`
- **Parser system**: Calls `LinkParser(config).parse_file()` — no changes to parsers
- **CLI**: Adds one arg to argparse in `main.py`, early-exit branch before service startup
- **No database interaction** — validation scans fresh, no LinkDatabase usage

## Testing Strategy

### Unit Testing

Framework: pytest (existing project standard)

Key test scenarios:
- File with valid links → no broken links reported
- File with broken link → correctly identified with file, line, target
- Anchor handling → `file.md#section` checks `file.md` existence
- URL filtering → http/https links skipped
- Python import targets skipped
- Ignored directories respected
- Monitored extensions respected
- Empty workspace → clean result
- Mixed valid/broken → only broken reported
- Output file written to correct location
- Report format includes all required fields

### Test Data Requirements

- Temporary directory with controlled file structure
- Markdown files with valid and broken links
- YAML/JSON files with valid and broken references
- Files in ignored directories (should be skipped)
- Files with URL links (should be skipped)
- Files with anchor links to existing files

## Risk Assessment

### Technical Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|-----------|
| Parser returns targets that aren't real file paths (regex patterns, example text) | Medium | Medium | Use `looks_like_file_path()` filter + URL prefix filter. Already battle-tested in existing codebase |
| Python import targets (dot-separated module paths) | Low | High | Detect `link_type == "python-import"` and skip entirely |
| Performance on very large workspaces | Low | Low | Same walk pattern as `_initial_scan()` which handles 1000+ files efficiently |

### Schedule Risks

- None significant — all infrastructure exists, implementation is straightforward composition

## Implementation Artifacts

### Code Deliverables

| File | Action | Purpose |
|------|--------|---------|
| `linkwatcher/validator.py` | Create | Core validation logic, report generation |
| `main.py` | Modify | Add `--validate` CLI flag and early-exit branch |
| `test/automated/unit/test_validator.py` | Create | Unit tests |

## Success Criteria

1. `python main.py --validate` scans workspace and reports all broken file references to console
2. `LinkWatcherBrokenLinks.txt` written to run directory with full report
3. Exit code 0 (clean) when no broken links, exit code 1 when broken links found
4. Respects config (monitored extensions, ignored directories)
5. Output includes source file, line number, and broken target path for each issue
6. Unit tests pass covering core scenarios

## Related Documentation

- [Tier Assessment: ART-ASS-200](../../documentation-tiers/assessments/PD-ASS-200-6.1.1-link-validation.md)
- [Feature State: 6.1.1](<../../state-tracking/features/6.1.1-Link Validation-implementation-state.md>)
- [Feature Tracking](../../state-tracking/permanent/feature-tracking.md)
- [Task: Feature Implementation Planning (PF-TSK-044)](../../../../process-framework/tasks/04-implementation/feature-implementation-planning-task.md)

---

**Last Updated**: 2026-03-24
**Status**: Planning
**Owner**: AI Agent & Human Partner
